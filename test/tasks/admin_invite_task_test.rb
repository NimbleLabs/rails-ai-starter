require "test_helper"
require "rake"

# bin/rails admin:invite, as NimbleHQ runs it at launch:
#   dokku run --env ADMIN_PASSWORD=... <app> bin/rails admin:invite EMAIL=...
class AdminInviteTaskTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:invite")
    @saved_env = %w[EMAIL ADMIN_PASSWORD].index_with { |key| ENV[key] }
  end

  teardown do
    @saved_env.each { |key, value| ENV[key] = value }
    Rake::Task["admin:invite"].reenable
  end

  # Runs the task. Returns what it printed and whether it stopped with an error.
  def invite(email:, password: nil)
    ENV["EMAIL"] = email
    ENV["ADMIN_PASSWORD"] = password
    Rake::Task["admin:invite"].reenable
    aborted = false
    out, err = capture_io do
      Rake::Task["admin:invite"].invoke
    rescue SystemExit
      aborted = true
    end
    { out:, err:, aborted: }
  end

  test "with ADMIN_PASSWORD it creates the admin with that password and sends no email" do
    run = nil
    assert_no_emails { run = invite(email: "owner@example.com", password: "a-long-launch-password") }

    user = User.find_by!(email: "owner@example.com")
    assert user.admin?
    assert user.valid_password?("a-long-launch-password")
    assert_match "Created owner@example.com as an admin with the password from ADMIN_PASSWORD. No email sent.", run[:out]
  end

  test "with ADMIN_PASSWORD it leaves an existing account's password alone and says so" do
    user = users(:one)
    digest = user.encrypted_password

    run = nil
    assert_no_emails { run = invite(email: user.email, password: "a-long-launch-password") }

    assert_equal digest, user.reload.encrypted_password
    assert_match "already had an account, so their password is unchanged", run[:out]
  end

  test "without ADMIN_PASSWORD it emails the set-password link" do
    run = nil
    assert_emails(1) { run = invite(email: "owner@example.com") }

    assert_match "The set-password email is on its way", run[:out]
  end

  test "a short ADMIN_PASSWORD stops with the reason and creates nothing" do
    run = nil
    assert_no_difference("User.count") { run = invite(email: "owner@example.com", password: "too-short") }

    assert run[:aborted]
    assert_match "ADMIN_PASSWORD must be at least #{User::ADMIN_PASSWORD_MIN_LENGTH} characters", run[:err]
  end

  test "without EMAIL it shows how to run it" do
    run = invite(email: nil)

    assert run[:aborted]
    assert_match "Usage: bin/rails admin:invite EMAIL=", run[:err]
  end
end
