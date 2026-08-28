require "application_system_test_case"

# Mobile-viewport behaviour for the admin SPA.
#
# The admin has to be usable on a phone, which mostly comes down to three
# things: the sidebar must not eat the screen, lists must not force horizontal
# scrolling, and the page must not be wider than the viewport.
class AdminMobileTest < ApplicationSystemTestCase
  IPHONE  = [ 390, 844 ].freeze
  DESKTOP = [ 1400, 1400 ].freeze

  include Warden::Test::Helpers

  # Rails reuses one browser window across system-test classes, so `driven_by`'s
  # screen_size does not re-apply when another class ran first. Resize
  # explicitly, and put it back afterwards so test order stays irrelevant.
  setup do
    page.driver.browser.manage.window.resize_to(*IPHONE)
    login_as users(:one), scope: :user
    Log.delete_all
    3.times { |i| Log.record("mobile layout check #{("a".."z").to_a[i]}", source: "web") }
  end

  teardown do
    page.driver.browser.manage.window.resize_to(*DESKTOP)
  end

  def page_overflows?
    page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth + 1")
  end

  test "the sidebar is a drawer, not a permanent column" do
    visit "/admin"

    # The desktop sidebar is hidden at this width; a hamburger opens the drawer.
    assert_selector "button[aria-label='Open navigation']", visible: true
    assert_no_selector "nav[aria-label='Admin']", visible: true

    find("button[aria-label='Open navigation']").click
    assert_selector "nav[aria-label='Admin']", visible: true

    # Navigating from the drawer closes it.
    within("nav[aria-label='Admin']") { click_on "Logs" }
    assert_selector "h1", text: "Logs"
    assert_no_selector "nav[aria-label='Admin']", visible: true
  end

  test "lists render as cards instead of a table" do
    visit "/admin/logs"
    assert_selector "h1", text: "Logs"

    # DataTable swaps the <table> for a card list below the md breakpoint.
    assert_no_selector "table", visible: true
    assert_text "mobile layout check"
  end

  test "no page scrolls horizontally on a phone" do
    %w[
      /admin
      /admin/users
      /admin/contacts
      /admin/articles
      /admin/features
      /admin/logs
      /admin/log-notifications
      /admin/funnel-metrics
    ].each do |path|
      visit path
      assert_selector "h1", wait: 5
      assert_not page_overflows?, "#{path} scrolls horizontally at #{IPHONE.first}px wide"
    end
  end

  test "the user app fits a phone too" do
    visit "/app"
    assert_selector "h1", wait: 5
    assert_not page_overflows?, "/app scrolls horizontally at #{IPHONE.first}px wide"
  end
end
