# The public "What's new" list for /whats-new, read from NimbleHQ's feed for
# this product (WHATS_NEW_FEED_URL, set when NimbleHQ launches the app). The
# builder agent adds an entry whenever it ships something users will notice.
#
# The site must never depend on NimbleHQ being up: the fetch is short, the result
# is cached for 15 minutes, and the last good copy is kept with no expiry so a
# failed fetch shows it instead. With no copy at all, #entries is empty and the
# page says so. Without the setting, the page and its footer link are hidden.
class WhatsNewFeed
  TIMEOUT = 3
  FRESH_FOR = 15.minutes
  # After a failure, serve the fallback this long before trying again, so a down
  # feed does not cost every visitor the full timeout.
  RETRY_AFTER = 1.minute
  FRESH_KEY = "whats_new/v1/fresh".freeze
  LAST_GOOD_KEY = "whats_new/v1/last_good".freeze

  Entry = Data.define(:shipped_on, :title, :summary)

  class << self
    # Swappable in tests (Faraday's :test adapter).
    attr_writer :adapter
    def adapter = @adapter || [ Faraday.default_adapter ]

    def url = ENV["WHATS_NEW_FEED_URL"].presence
    def enabled? = url.present?

    def entries
      return [] unless enabled?
      rows = Rails.cache.read(FRESH_KEY) || refresh
      rows.filter_map { |row| to_entry(row) }
    end

    private

    def refresh
      rows = fetch
      Rails.cache.write(LAST_GOOD_KEY, rows)
      Rails.cache.write(FRESH_KEY, rows, expires_in: FRESH_FOR)
      rows
    rescue StandardError => e
      Rails.logger.warn("[whats_new] feed fetch failed: #{e.class}: #{e.message}")
      rows = Rails.cache.read(LAST_GOOD_KEY) || []
      Rails.cache.write(FRESH_KEY, rows, expires_in: RETRY_AFTER)
      rows
    end

    def fetch
      conn = Faraday.new(request: { timeout: TIMEOUT, open_timeout: TIMEOUT }) do |f|
        f.response :raise_error
        f.adapter(*adapter)
      end
      features = JSON.parse(conn.get(url).body).fetch("features")
      raise ArgumentError, "features is not a list" unless features.is_a?(Array)
      features.map { |f| f.to_h.slice("shipped_on", "title", "summary") }
    end

    def to_entry(row)
      title = row["title"].to_s.strip
      return if title.empty?
      Entry.new(shipped_on: Date.iso8601(row["shipped_on"].to_s), title:, summary: row["summary"].to_s.strip)
    rescue Date::Error
      nil
    end
  end
end
