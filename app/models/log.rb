# The internal exception / error log. This is the app's replacement for Rollbar.
#
# Two ways rows get here:
#   1. Automatically, via LogErrorSubscriber (config/initializers/error_reporting.rb):
#      unhandled exceptions in web requests (500s only — Rails already excludes
#      404s, bad params, CSRF failures), jobs that exhausted their retries, and
#      anything passed to `Rails.error.report`.
#   2. Deliberately, from code: `Log.error(e, context: {...})`, `Log.warn("...")`,
#      or `POST /api/v1/logs` from the mobile app.
#
# Keep it surgical. Every row costs an admin's attention — log what a human
# needs to act on, not what happened. Same-fingerprint repeats within
# DEDUPE_WINDOW roll up into one row (occurrences++) so a hot loop can't flood
# the table or the notification channels.
class Log < ApplicationRecord
  LEVELS  = { info: 0, warn: 1, error: 2, fatal: 3 }.freeze
  SOURCES = %w[web job mobile console app].freeze

  DEDUPE_WINDOW     = 24.hours
  MAX_MESSAGE_BYTES = 4_000
  MAX_BACKTRACE_LINES = 60
  MAX_CONTEXT_BYTES = 16_000
  MAX_CONTEXT_DEPTH = 4
  MAX_CONTEXT_ENTRIES = 50
  MAX_CONTEXT_VALUE_BYTES = 2_000

  enum :level, LEVELS, default: :error, validate: true

  belongs_to :user, optional: true

  validates :message, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :fingerprint, presence: true

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved,   -> { where.not(resolved_at: nil) }
  scope :recent,     -> { order(last_seen_at: :desc) }
  scope :at_or_above, ->(level) { where(level: LEVELS.select { |_, v| v >= LEVELS.fetch(level.to_sym) }.keys) }
  scope :from_source, ->(source) { where(source: source) }
  scope :search, ->(q) {
    q = q.to_s.strip
    next all if q.blank?
    where("logs.message ILIKE :q OR logs.error_class ILIKE :q OR logs.path ILIKE :q", q: "%#{sanitize_sql_like(q)}%")
  }

  after_commit :enqueue_notification, on: %i[create update], if: :notify_after_commit?

  class << self
    # Record an exception or a message. Never raises — logging must never take
    # down the code path that called it. Returns the Log (new or rolled-up) or nil.
    #
    #   Log.record(e, level: :error, source: "job", context: { job: self.class.name })
    #   Log.record("Stripe webhook signature mismatch", level: :warn, source: "web")
    def record(error_or_message, level: :error, source: nil, context: {}, user: nil, backtrace: nil, error_class: nil)
      attrs = build_attributes(error_or_message, level:, source:, context:, user:, backtrace:, error_class:)
      now = Time.current

      existing = unresolved.where(fingerprint: attrs[:fingerprint]).where("last_seen_at > ?", now - DEDUPE_WINDOW).order(last_seen_at: :desc).first
      if existing
        existing.occurrences += 1
        existing.last_seen_at = now
        existing.level = attrs[:level] if LEVELS[attrs[:level].to_sym] > LEVELS[existing.level.to_sym]
        existing.context = existing.context.merge("last_context" => attrs[:context]) if attrs[:context].present?
        existing.save!
        existing
      else
        create!(attrs.merge(last_seen_at: now))
      end
    rescue Interrupt, SignalException, SystemExit
      # Never swallow a shutdown signal.
      raise
    rescue Exception => e
      # Deliberately broader than StandardError: recording a log must not be
      # able to take down the code path that called it, and the pathological
      # cases here (SystemStackError, NoMemoryError) are not StandardErrors.
      Rails.logger.error("[Log.record] failed to record log: #{e.class}: #{e.message}")
      nil
    end

    def error(error_or_message, **opts) = record(error_or_message, **opts, level: :error)
    def warn(error_or_message, **opts)  = record(error_or_message, **opts, level: :warn)
    def info(error_or_message, **opts)  = record(error_or_message, **opts, level: :info)
    def fatal(error_or_message, **opts) = record(error_or_message, **opts, level: :fatal)

    # Stable identity for "the same problem": class + normalized message + the
    # first application frame. Numbers/ids/uuids/hex are stripped from the
    # message so `Couldn't find User with id=42` and `...id=43` roll up together.
    def fingerprint_for(error_class, message, backtrace)
      normalized = message.to_s.gsub(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i, "<uuid>")
                                .gsub(/\b0x[0-9a-f]+\b/i, "<hex>")
                                .gsub(/\d+/, "<n>")
                                .strip.first(500)
      frame = Array(backtrace).find { |line| line.to_s.include?("/app/") || line.to_s.start_with?("app/") }.to_s
      frame = frame.sub(/:\d+:in .*$/, "") # drop line number + method: line shifts shouldn't split a group
      Digest::SHA1.hexdigest([ error_class.to_s, normalized, frame ].join("|"))
    end

    private

    def build_attributes(error_or_message, level:, source:, context:, user:, backtrace:, error_class:)
      if error_or_message.is_a?(Exception)
        e = error_or_message
        message     = e.message.presence || e.class.name
        error_class ||= e.class.name
        backtrace   ||= e.backtrace
        if e.cause && e.cause != e
          context = context.merge(cause: "#{e.cause.class}: #{e.cause.message}".first(500))
        end
      else
        message = error_or_message.to_s.presence || "(no message)"
      end

      cleaned = clean_backtrace(backtrace)
      context = sanitize_context(context)
      source  = (source.presence || context["source"].presence || "app").to_s
      source  = "app" unless SOURCES.include?(source)
      level   = level.to_s.presence_in(LEVELS.keys.map(&:to_s)) || "error"

      {
        level:       level,
        source:      source,
        message:     message.to_s.byteslice(0, MAX_MESSAGE_BYTES).scrub,
        error_class: error_class&.to_s&.first(255),
        backtrace:   cleaned.presence&.join("\n"),
        context:     context,
        fingerprint: fingerprint_for(error_class, message, cleaned),
        user_id:     user&.id || context["user_id"],
        request_id:  context["request_id"]&.to_s&.first(255),
        path:        context["path"]&.to_s&.first(255)
      }
    end

    def clean_backtrace(backtrace)
      lines = Array(backtrace).map(&:to_s)
      return [] if lines.empty?
      cleaned = Rails.backtrace_cleaner.clean(lines)
      cleaned = lines if cleaned.empty?
      cleaned.first(MAX_BACKTRACE_LINES)
    end

    # Context arrives from anywhere — controllers, jobs, third-party gems, the
    # error reporter — so it can contain arbitrary objects. Coerce everything to
    # JSON primitives with a hard depth limit and never serialize an unknown
    # object: some Rails internals (routing nodes, for one) are Enumerables that
    # recurse forever under `to_json` and would take the stack down with them.
    def sanitize_context(context)
      hash = coerce(context, 0)
      hash = {} unless hash.is_a?(Hash)
      hash = hash.reject { |_, v| v.nil? }

      json = JSON.generate(hash)
      return hash if json.bytesize <= MAX_CONTEXT_BYTES

      { "truncated" => true, "preview" => json.byteslice(0, 1_000).scrub }
    rescue Exception => e
      { "context_error" => "#{e.class}: #{e.message}".first(500) }
    end

    def coerce(value, depth)
      return "(too deep)" if depth > MAX_CONTEXT_DEPTH

      case value
      when nil, true, false, Numeric then value
      when String then value.byteslice(0, MAX_CONTEXT_VALUE_BYTES).to_s.scrub
      when Symbol then value.to_s
      when Time, DateTime, Date then value.iso8601
      when Hash
        value.first(MAX_CONTEXT_ENTRIES).to_h { |k, v| [ k.to_s, coerce(v, depth + 1) ] }
      when Array
        value.first(MAX_CONTEXT_ENTRIES).map { |v| coerce(v, depth + 1) }
      when ActionController::Parameters
        coerce(value.to_unsafe_h, depth)
      else
        # Anything else becomes a short string. `to_s` is overridden far more
        # safely than `to_json` is implemented.
        (value.to_s rescue "(unprintable #{value.class})").byteslice(0, MAX_CONTEXT_VALUE_BYTES).to_s.scrub
      end
    rescue Exception
      "(uncoercible)"
    end
  end

  def resolve!(by: nil)
    update!(resolved_at: Time.current, context: context.merge("resolved_by" => by&.email).compact)
  end

  def unresolve!
    update!(resolved_at: nil)
  end

  def resolved? = resolved_at.present?

  def title
    error_class.present? ? "#{error_class}: #{message.lines.first.to_s.strip}" : message.lines.first.to_s.strip
  end

  def level_value = LEVELS.fetch(level.to_sym)

  def notified_recently?(minutes)
    notified_at.present? && notified_at > minutes.to_i.minutes.ago
  end

  private

  # Notify on create, and on a roll-up (occurrence bump). Never on resolve /
  # unresolve edits, which only touch resolved_at / context.
  def notify_after_commit?
    return false if destroyed?
    return true if previously_new_record?
    saved_change_to_occurrences?
  end

  def enqueue_notification
    return unless LogSubscription.active.exists?
    LogNotificationJob.perform_later(id)
  rescue => e
    Rails.logger.error("[Log] could not enqueue notification: #{e.class}: #{e.message}")
  end
end
