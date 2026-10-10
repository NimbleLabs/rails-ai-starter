require "application_system_test_case"
require_relative "../support/quality_report_fixture"

# Smoke tests for the React admin SPA.
#
# These are the only tests that prove React actually mounts: everything else
# stops at the server-rendered shell. They drive the real bundle, so a runtime
# error in a page component fails here rather than in front of an admin.
class AdminSpaTest < ApplicationSystemTestCase
  include QualityReportFixture

  setup do
    @admin = users(:one)
    login_as @admin, scope: :user
  end

  test "dashboard mounts and renders Ahoy metrics" do
    visit "/admin"

    assert_selector "h1", text: "Dashboard"
    assert_text "Visits"
    assert_text "Unique visitors"
    assert_text "New users"
    # The sidebar is the shell; if it rendered, the layout mounted.
    assert_selector "nav[aria-label='Admin']"
  end

  test "client-side navigation works without a full page load" do
    visit "/admin"
    click_on "Logs"

    assert_selector "h1", text: "Logs"
    assert_current_path "/admin/logs"

    click_on "Users"
    assert_selector "h1", text: "Users"
    assert_current_path "/admin/users"
  end

  test "every admin page mounts without a runtime error" do
    pages = {
      "/admin" => "Dashboard",
      "/admin/users" => "Users",
      "/admin/contacts" => "Contacts",
      "/admin/email-templates" => "Email",
      "/admin/articles" => "Articles",
      "/admin/funnels" => "Funnels",
      "/admin/funnel-metrics" => "Funnel",
      "/admin/features" => "Features",
      "/admin/logs" => "Logs",
      "/admin/log-notifications" => "notifications",
      "/admin/quality" => "Quality",
      "/admin/theme" => "Theme"
    }

    pages.each do |path, heading|
      visit path
      assert_selector "h1", text: /#{Regexp.escape(heading)}/i, wait: 5
      assert_no_text "Not yet ported"
      assert_no_text "Something went wrong"
    end
  end

  test "a deep link into the SPA is served by the Rails catch-all" do
    visit "/admin/logs"
    assert_selector "h1", text: "Logs"
  end

  test "the quality page shows the committed report" do
    QualityReport.stub(:current, quality_report) do
      visit "/admin/quality"

      assert_selector "h1", text: "Quality"
      assert_text "All green"
      assert_text "158 tests pass with 83.0% line coverage"
      assert_selector "[role=meter][aria-label='Line coverage'][aria-valuenow='83']"
      assert_text QualityReportFixture::LONG_PATH
      assert_text "Line coverage across the last 4 reports: 78.0% → 83.0%"
    end
  end

  test "the quality page leads with what's wrong" do
    QualityReport.stub(:current, quality_report(failing: true, stale: true)) do
      visit "/admin/quality"

      assert_text "Failing."
      assert_text "Tests pass needs attention"
      assert_text "Failing and skipped tests"
      assert_text "Changed since this run"
    end
  end

  test "the quality page explains how to make a report when there isn't one" do
    QualityReport.stub(:current, nil) do
      visit "/admin/quality"

      assert_text "No report yet"
      assert_text "bin/rails quality"
    end
  end

  test "unknown admin routes render the in-app not-found page" do
    visit "/admin/nope-not-a-page"
    assert_selector "h1", text: "Page not found"
  end

  test "the user app mounts too" do
    visit "/app"
    assert_selector "h1", text: /Welcome/
  end
end
