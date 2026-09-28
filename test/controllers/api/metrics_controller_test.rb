require "test_helper"

class Api::MetricsControllerTest < ActionDispatch::IntegrationTest
  TOKEN = "m" * 40
  DAY = Date.new(2026, 9, 27)

  setup do
    ENV["NIMBLEHQ_METRICS_TOKEN"] = TOKEN
    ENV["APP_HOST"] = "www.example.org"
  end

  teardown do
    ENV.delete("NIMBLEHQ_METRICS_TOKEN")
    ENV.delete("APP_HOST")
  end

  def visit!(visitor:, referrer: nil, pages: [ "/" ], user: nil, at: DAY.in_time_zone.noon)
    visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: visitor, referring_domain: referrer, user:, started_at: at)
    pages.each { |page| Ahoy::Event.create!(visit:, name: "$view", properties: { page: }, time: at) }
    visit
  end

  def daily(date: DAY, token: TOKEN)
    get "/api/metrics/daily", params: { date: date.iso8601 }, headers: { "Authorization" => "Bearer #{token}" }
  end

  test "counts people, not crawlers or admins, and who came from other sites" do
    visit!(visitor: "a", referrer: "www.google.com", pages: [ "/charts/rent", "/charts/rent", "/" ])
    visit!(visitor: "a", pages: [ "/charts/rent" ])                  # the same person again, direct
    visit!(visitor: "b", referrer: "www.example.org", pages: [ "/" ]) # clicked around our own site
    visit!(visitor: "c", referrer: "news.ycombinator.com", pages: [ "/charts/gas" ])
    visit!(visitor: "crawler", referrer: "www.google.com", pages: [])     # never ran our JavaScript
    visit!(visitor: "harris", user: users(:one))                           # an admin, signed in
    visit!(visitor: "harris", pages: [ "/charts/rent" ])                   # the same admin, signed out
    visit!(visitor: "d", at: (DAY - 1).in_time_zone.noon)                  # the day before

    daily
    assert_response :success
    body = response.parsed_body
    assert_equal "2026-09-27", body["date"]
    assert_equal 3, body["visitors"]
    assert_equal 4, body["visits"]
    assert_equal 2, body["outside_visitors"]
    assert_equal({ "path" => "/charts/rent", "views" => 3 }, body["top_pages"].first)
    assert_equal [ "news.ycombinator.com", "www.google.com" ], body["top_sources"].map { it["source"] }.sort
  end

  test "counts sign-ups that day, but not admins" do
    User.create!(email: "new@example.com", password: "password123", name: "New", created_at: DAY.in_time_zone.noon)
    daily
    assert_equal 1, response.parsed_body["signups"]
  end

  test "needs the shared token, and doesn't exist without one" do
    daily(token: "wrong")
    assert_response :unauthorized

    ENV.delete("NIMBLEHQ_METRICS_TOKEN")
    daily
    assert_response :not_found
  end

  test "refuses a bad date" do
    get "/api/metrics/daily", params: { date: "yesterday" }, headers: { "Authorization" => "Bearer #{TOKEN}" }
    assert_response :bad_request
  end
end
