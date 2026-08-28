require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Sign in without driving the login form — Warden's test helper puts the user
  # straight into the session, which keeps system tests about the thing under
  # test rather than about Devise.
  include Warden::Test::Helpers

  teardown { Warden.test_reset! }
end
