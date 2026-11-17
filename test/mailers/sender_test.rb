require "test_helper"

# SendGrid refuses mail from an address it hasn't verified (550, and the request
# that sent it fails), so every email, Devise's included, must come from
# ApplicationMailer.from_address.
class SenderTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @mail_from = ENV["MAIL_FROM"]
    ENV.delete("MAIL_FROM")
  end

  teardown { ENV["MAIL_FROM"] = @mail_from }

  def request_password_reset
    assert_emails(1) { post user_password_path, params: { user: { email: users(:one).email } } }
    ActionMailer::Base.deliveries.last
  end

  test "the forgot-password email comes from the verified default sender" do
    mail = request_password_reset

    assert_response :redirect
    assert_equal "Harris Reynolds <harris@nimblelabs.com>", mail[:from].value
  end

  test "the app's own emails come from the same sender" do
    mail = UserMailer.with(user: users(:one)).welcome_email.deliver_now

    assert_equal ApplicationMailer::DEFAULT_FROM, mail[:from].value
  end

  test "MAIL_FROM overrides the sender for Devise and the app alike" do
    ENV["MAIL_FROM"] = "Demo App <demo@example.com>"

    assert_equal [ "demo@example.com" ], request_password_reset.from
    assert_equal [ "demo@example.com" ], UserMailer.with(user: users(:one)).welcome_email.deliver_now.from
  end

  test "a blank MAIL_FROM falls back to the default" do
    ENV["MAIL_FROM"] = ""

    assert_equal ApplicationMailer::DEFAULT_FROM, ApplicationMailer.from_address
  end
end
