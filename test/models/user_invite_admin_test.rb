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
end
