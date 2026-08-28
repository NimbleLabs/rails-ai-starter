require "test_helper"

class DashboardMetricsTest < ActiveSupport::TestCase
  setup do
    Ahoy::Event.delete_all
    Ahoy::Visit.delete_all
    Log.delete_all
  end

  def visit!(started_at: Time.current, **attrs)
    Ahoy::Visit.create!(
      {
        visit_token: SecureRandom.uuid,
        visitor_token: SecureRandom.uuid,
        started_at: started_at
      }.merge(attrs)
    )
  end

  test "clamps the requested range" do
    assert_equal 1, DashboardMetrics.new(days: 0).days
    assert_equal 1, DashboardMetrics.new(days: -5).days
    assert_equal 1, DashboardMetrics.new(days: "not a number").days, "to_i turns junk into 0, which clamps to 1"
    assert_equal DashboardMetrics::MAX_DAYS, DashboardMetrics.new(days: 10_000).days
    assert_equal 30, DashboardMetrics.new(days: "30").days, "params arrive as strings"
  end

  test "counts visits, visitors and events in range" do
    token = SecureRandom.uuid
    visit!(visitor_token: token)
    visit!(visitor_token: token)
    visit!
    visit!(started_at: 90.days.ago)

    metrics = DashboardMetrics.new(days: 30).as_json

    assert_equal 3, metrics[:totals][:visits], "the 90-day-old visit is out of range"
    assert_equal 2, metrics[:totals][:visitors], "two visits share a visitor token"
  end

  test "counts today's visits separately" do
    visit!(started_at: Time.current)
    visit!(started_at: 3.days.ago)

    assert_equal 1, DashboardMetrics.new(days: 30).as_json[:totals][:visits_today]
  end

  test "visits_by_day is dense and covers the whole range" do
    visit!(started_at: 2.days.ago)

    series = DashboardMetrics.new(days: 7).as_json[:visits_by_day]

    assert_equal 7, series.size, "every day in the range should be present, zero-filled"
    assert_equal 1, series.sum { |point| point[:count] }
    assert series.all? { |point| point.key?(:date) && point.key?(:count) }
    assert_equal series.map { |p| p[:date] }.sort, series.map { |p| p[:date] }, "days must be in order"
  end

  test "top events are ranked and limited" do
    visit = visit!
    3.times { Ahoy::Event.create!(visit: visit, name: "app_opened", time: Time.current, properties: {}) }
    Ahoy::Event.create!(visit: visit, name: "push_opened", time: Time.current, properties: {})

    top = DashboardMetrics.new(days: 30).as_json[:top_events]

    assert_equal({ name: "app_opened", count: 3 }, top.first)
    assert_operator top.size, :<=, DashboardMetrics::TOP_N
  end

  test "landing pages are shortened to a path" do
    visit!(landing_page: "https://example.com/pricing?utm_source=x")

    page = DashboardMetrics.new(days: 30).as_json[:top_landing_pages].first
    assert_match "/pricing", page[:page]
    assert_not_includes page[:page], "https://example.com"
  end

  test "referrers exclude blanks" do
    visit!(referring_domain: "google.com")
    visit!(referring_domain: nil)
    visit!(referring_domain: "")

    referrers = DashboardMetrics.new(days: 30).as_json[:top_referrers]
    assert_equal [ { domain: "google.com", count: 1 } ], referrers
  end

  test "device types label missing values as unknown" do
    visit!(device_type: "mobile")
    visit!(device_type: nil)

    types = DashboardMetrics.new(days: 30).as_json[:device_types]
    assert_includes types.map { |row| row[:type] }, "unknown"
  end

  test "includes the unresolved log summary" do
    Log.record("boom", source: "web", level: :error)

    assert_equal 1, DashboardMetrics.new(days: 30).as_json[:logs][:unresolved]
  end

  test "returns zeroed numbers on an empty database rather than failing" do
    metrics = DashboardMetrics.new(days: 30).as_json

    assert_equal 0, metrics[:totals][:visits]
    assert_empty metrics[:top_events]
    assert_empty metrics[:top_referrers]
    assert_equal 30, metrics[:visits_by_day].size
  end
end
