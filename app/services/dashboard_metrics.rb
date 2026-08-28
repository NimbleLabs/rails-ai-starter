# Admin dashboard numbers, read straight out of Ahoy's own tables.
#
# This is the payoff of keeping analytics in our Postgres rather than a hosted
# SDK: every number here is a plain SQL aggregate that joins against `users`,
# and it costs one request. See CLAUDE.md → "Analytics (Ahoy)".
class DashboardMetrics
  DEFAULT_DAYS = 30
  MAX_DAYS     = 365
  TOP_N        = 5

  attr_reader :days, :since

  def initialize(days: DEFAULT_DAYS)
    @days  = days.to_i.clamp(1, MAX_DAYS)
    @since = @days.days.ago.beginning_of_day
  end

  def as_json(*)
    {
      range: { days: days, since: since.iso8601 },
      totals: totals,
      visits_by_day: visits_by_day,
      top_events: top_events,
      top_landing_pages: top_landing_pages,
      top_referrers: top_referrers,
      device_types: device_types,
      recent_signups: recent_signups,
      logs: log_summary
    }
  end

  private

  def visits  = @visits ||= Ahoy::Visit.where(started_at: since..)
  def events  = @events ||= Ahoy::Event.where(time: since..)

  def totals
    {
      visits:            visits.count,
      visitors:          visits.distinct.count(:visitor_token),
      events:            events.count,
      signups:           User.where(created_at: since..).count,
      visits_today:      Ahoy::Visit.where(started_at: Time.current.beginning_of_day..).count,
      total_users:       User.count,
      # Share of visits that produced at least one event — a rough engagement read.
      engaged_visits:    events.distinct.count(:visit_id)
    }
  end

  # A dense series (zero-filled) so the client can render a bar chart without
  # worrying about missing days.
  def visits_by_day
    counts = visits.group("DATE(started_at)").count.transform_keys(&:to_s)
    (0...days).map do |offset|
      date = (since.to_date + offset)
      { date: date.iso8601, count: counts[date.to_s].to_i }
    end
  end

  def top_events
    events.group(:name).order(count_all: :desc).limit(TOP_N).count
          .map { |name, count| { name: name.presence || "(unnamed)", count: count } }
  end

  def top_landing_pages
    visits.where.not(landing_page: nil).group(:landing_page).order(count_all: :desc).limit(TOP_N).count
          .map { |page, count| { page: shorten_path(page), count: count } }
  end

  def top_referrers
    visits.where.not(referring_domain: [ nil, "" ]).group(:referring_domain)
          .order(count_all: :desc).limit(TOP_N).count
          .map { |domain, count| { domain: domain, count: count } }
  end

  def device_types
    visits.group(:device_type).count
          .map { |type, count| { type: type.presence || "unknown", count: count } }
          .sort_by { |row| -row[:count] }
  end

  def recent_signups
    User.where(created_at: since..).order(created_at: :desc).limit(TOP_N)
        .map { |user| { id: user.id, slug: user.slug, name: user.name, email: user.email, created_at: user.created_at.iso8601 } }
  end

  # Surfaced here so the dashboard shows whether anything is on fire without a
  # second request. See app/models/log.rb.
  def log_summary
    {
      unresolved: Log.unresolved.count,
      errors_24h: Log.unresolved.at_or_above(:error).where(last_seen_at: 24.hours.ago..).count
    }
  end

  def shorten_path(url)
    return url if url.blank?
    uri = URI.parse(url)
    path = uri.path.presence || "/"
    uri.query.present? ? "#{path}?#{uri.query.truncate(40)}" : path
  rescue URI::InvalidURIError
    url.to_s.truncate(80)
  end
end
