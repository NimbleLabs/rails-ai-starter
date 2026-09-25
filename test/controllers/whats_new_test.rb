require "test_helper"

class WhatsNewTest < ActionDispatch::IntegrationTest
  URL = "https://nimblehq.test/public/starter/whats-new.json".freeze
  FEED = {
    project: "Starter",
    features: [
      { shipped_on: "2026-09-24", title: "Sort markets by gap, jobs or population", summary: "Reorder the report market list." },
      { shipped_on: "2026-08-28", title: "See what changed since the last edition", summary: "Rooms, jobs and the gap, edition over edition." }
    ]
  }.to_json

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @stubs = Faraday::Adapter::Test::Stubs.new
    WhatsNewFeed.adapter = [ :test, @stubs ]
    ENV["WHATS_NEW_FEED_URL"] = URL
  end

  teardown do
    Rails.cache = @original_cache
    WhatsNewFeed.adapter = nil
    ENV.delete("WHATS_NEW_FEED_URL")
  end

  test "a successful fetch lists entries under month headings, newest first" do
    @stubs.get(URL) { [ 200, { "Content-Type" => "application/json" }, FEED ] }

    get whats_new_url
    assert_response :success
    body = response.body
    assert_match "September 2026", body
    assert_match "Sep 24, 2026", body
    assert_match "Sort markets by gap, jobs or population", body
    assert_match "Reorder the report market list.", body
    assert_operator body.index("September 2026"), :<, body.index("August 2026")
    assert_no_match(/Nothing to show yet/, body)
  end

  test "the result is cached, so a second visit does not fetch again" do
    calls = 0
    @stubs.get(URL) { calls += 1; [ 200, {}, FEED ] }

    2.times { get whats_new_url }
    assert_equal 1, calls
  end

  test "a failed fetch shows the last good copy" do
    Rails.cache.write(WhatsNewFeed::LAST_GOOD_KEY, JSON.parse(FEED)["features"])
    @stubs.get(URL) { raise Faraday::TimeoutError }

    get whats_new_url
    assert_response :success
    assert_match "Sort markets by gap, jobs or population", response.body
  end

  test "a failed or malformed fetch with nothing cached says there is nothing to show" do
    @stubs.get(URL) { [ 200, {}, "<html>not json</html>" ] }

    get whats_new_url
    assert_response :success
    assert_match "Nothing to show yet", response.body
  end

  test "the footer links to the page" do
    get about_url
    assert_select "footer a[href=?]", whats_new_path
  end

  test "without a feed URL the page is not found and the footer has no link" do
    ENV.delete("WHATS_NEW_FEED_URL")

    get about_url
    assert_select "footer a[href=?]", whats_new_path, count: 0

    get whats_new_url
    assert_response :not_found
  end
end
