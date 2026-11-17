require "test_helper"

class UserInviteAdminTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "creates an admin and emails a working set-password link, without the sign-up welcome" do
    user = nil
    assert_emails 1 do
      assert_no_enqueued_emails { user = User.invite_admin!("  Owner@Example.com ") }
    end

    assert_equal "owner@example.com", user.email
    assert user.admin?

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "owner@example.com" ], mail.to
    assert_match "admin account is ready", mail.subject
    token = mail.text_part.body.to_s[/reset_password_token=([^\s&]+)/, 1]
    assert_equal user, User.with_reset_password_token(token)
    assert_match "http://example.com/admin", mail.text_part.body.to_s
  end

  test "makes an existing user an admin and keeps their password" do
    user = users(:one)
    user.update!(role: :user)
    digest = user.encrypted_password

    assert_emails 1 do
      assert_no_difference("User.count") { User.invite_admin!(user.email.upcase) }
    end
    assert user.reload.admin?
    assert_equal digest, user.encrypted_password
  end

  test "running it again sends a fresh link" do
    User.invite_admin!("owner@example.com")
    assert_emails 1 do
      assert_no_difference("User.count") { User.invite_admin!("owner@example.com") }
    end
  end

  test "an invalid email is refused" do
    assert_raises(ActiveRecord::RecordInvalid) { User.invite_admin!("not-an-email") }
  end

  test "with a password, a new admin gets that password and no email" do
    user = nil
    assert_no_emails do
      assert_no_enqueued_emails { user = User.invite_admin!("owner@example.com", password: "a-long-launch-password") }
    end

    assert user.admin?
    assert user.valid_password?("a-long-launch-password")
    assert_nil user.reset_password_token, "no set-password link is left lying around"
  end

  test "with a password, an existing account keeps its own password and gets no email" do
    user = users(:one)
    user.update!(role: :user)
    digest = user.encrypted_password

    assert_no_emails { User.invite_admin!(user.email, password: "a-long-launch-password") }

    assert user.reload.admin?
    assert_equal digest, user.encrypted_password
  end

  test "a password shorter than the minimum is refused before anything is created" do
    short = "x" * (User::ADMIN_PASSWORD_MIN_LENGTH - 1)

    error = nil
    assert_no_difference("User.count") do
      error = assert_raises(ArgumentError) { User.invite_admin!("owner@example.com", password: short) }
    end
    assert_match "at least #{User::ADMIN_PASSWORD_MIN_LENGTH} characters", error.message
    assert User.invite_admin!("owner@example.com", password: "x" * User::ADMIN_PASSWORD_MIN_LENGTH).admin?
  end

  test "a blank password means the emailed link, as without one" do
    assert_emails(1) { User.invite_admin!("owner@example.com", password: "  ") }
  end
end
