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

  def event!(visit, name, time: Time.current)
    Ahoy::Event.create!(visit: visit, name: name, time: time, properties: {})
  end

  test "top actions are ranked, limited and labelled in plain English" do
    visit = visit!
    3.times { event!(visit, "app_opened") }
    event!(visit, "push_opened")

    top = DashboardMetrics.new(days: 30).as_json[:top_actions]

    assert_equal({ name: "app_opened", label: "Opened the app", count: 3 }, top.first)
    assert_equal "Opened a notification", top.second[:label]
    assert_operator top.size, :<=, DashboardMetrics::TOP_N
  end

  test "top actions stop at TOP_N" do
    visit = visit!
    (DashboardMetrics::TOP_N + 2).times { |i| event!(visit, "thing_#{i}_done") }

    assert_equal DashboardMetrics::TOP_N, DashboardMetrics.new(days: 30).as_json[:top_actions].size
  end

  test "page views are left out of actions and engagement" do
    browsed = visit!
    3.times { event!(browsed, Analytics::PAGE_VIEW) }
    acted = visit!
    event!(acted, Analytics::PAGE_VIEW)
    event!(acted, Analytics::SIGN_UP)

    metrics = DashboardMetrics.new(days: 30).as_json

    assert_equal [ "sign_up" ], metrics[:top_actions].map { |row| row[:name] }
    assert_equal 1, metrics[:totals][:actions], "four page views and one sign-up is one action"
    assert_equal 1, metrics[:totals][:engaged_visits], "a visit that only loaded pages did nothing"
    assert_equal 2, metrics[:totals][:visits]
  end

  test "actions outside the range are not counted" do
    event!(visit!, Analytics::SIGN_IN, time: 45.days.ago)

    metrics = DashboardMetrics.new(days: 30).as_json

    assert_equal 0, metrics[:totals][:actions]
    assert_empty metrics[:top_actions]
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
    assert_empty metrics[:top_actions]
    assert_equal 0, metrics[:totals][:actions]
    assert_empty metrics[:top_referrers]
    assert_equal 30, metrics[:visits_by_day].size
  end
end
