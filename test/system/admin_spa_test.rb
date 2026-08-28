require "application_system_test_case"

# Smoke tests for the React admin SPA.
#
# These are the only tests that prove React actually mounts: everything else
# stops at the server-rendered shell. They drive the real bundle, so a runtime
# error in a page component fails here rather than in front of an admin.
class AdminSpaTest < ApplicationSystemTestCase
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
      "/admin/log-notifications" => "notifications"
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

  test "unknown admin routes render the in-app not-found page" do
    visit "/admin/nope-not-a-page"
    assert_selector "h1", text: "Page not found"
  end

  test "the user app mounts too" do
    visit "/app"
    assert_selector "h1", text: /Welcome/
  end
end
