require "test_helper"

class AnalyticsTest < ActiveSupport::TestCase
  test "known events read as plain English" do
    assert_equal "Signed up", Analytics.label(Analytics::SIGN_UP)
    assert_equal "Signed in", Analytics.label(Analytics::SIGN_IN)
    assert_equal "Opened the app", Analytics.label(Analytics::APP_OPENED)
    assert_equal "Opened a notification", Analytics.label(Analytics::PUSH_OPENED)
    assert_equal "Viewed a page", Analytics.label(Analytics::PAGE_VIEW)
  end

  test "every declared event has a label" do
    declared = Analytics.constants.map { |name| Analytics.const_get(name) }.select { |value| value.is_a?(String) }
    declared -= [ Analytics::WEB, Analytics::APP ]

    assert_empty declared - Analytics::LABELS.keys, "add a label to Analytics::LABELS for each new event"
  end

  test "an event without a label is tidied into words" do
    assert_equal "Article read", Analytics.label("article_read")
    assert_equal "Challenge started", Analytics.label("challenge.started")
    assert_equal "Click", Analytics.label("$click"), "ahoy.js names its own events with a $"
  end

  test "a blank or missing name still gets a label" do
    assert_equal "Unnamed event", Analytics.label("")
    assert_equal "Unnamed event", Analytics.label(nil)
    assert_equal "Unnamed event", Analytics.label("$")
  end

  test "labels accept symbols" do
    assert_equal "Signed up", Analytics.label(:sign_up)
  end
end
