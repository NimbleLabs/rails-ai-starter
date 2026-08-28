require "test_helper"

class UserOmniauthTest < ActiveSupport::TestCase
  def auth(uid: "google-123", email: "new@example.com", name: "New Person", verified: true, provider: "google_oauth2", image: nil)
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: name, image: image },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  test "creates a user from a verified Google identity" do
    user = nil
    assert_difference -> { User.count }, 1 do
      user = User.from_omniauth(auth)
    end

    assert user.persisted?
    assert_equal "new@example.com", user.email
    assert_equal "New Person", user.name
    assert_equal "google_oauth2", user.provider
    assert_equal "google-123", user.uid
    assert user.encrypted_password.present?, "needs a password to satisfy :validatable"
  end

  test "returns the same user on a second sign-in without creating a duplicate" do
    first = User.from_omniauth(auth)

    assert_no_difference -> { User.count } do
      second = User.from_omniauth(auth)
      assert_equal first.id, second.id
    end
  end

  test "refuses to create an account from an unverified Google email" do
    assert_no_difference -> { User.count } do
      assert_nil User.from_omniauth(auth(verified: false))
    end
  end

  test "links a Google identity to an existing local account when the email is verified" do
    local = users(:two)
    assert_nil local.provider

    assert_no_difference -> { User.count } do
      linked = User.from_omniauth(auth(email: local.email, uid: "google-abc"))
      assert_equal local.id, linked.id
    end

    local.reload
    assert_equal "google_oauth2", local.provider
    assert_equal "google-abc", local.uid
  end

  test "refuses to link to an existing account when Google has not verified the email" do
    local = users(:two)

    assert_nil User.from_omniauth(auth(email: local.email, verified: false)),
               "an unverified email must not take over a local account"
    assert_nil local.reload.provider
  end

  test "refuses to move an existing link to a different Google account" do
    local = users(:two)
    User.from_omniauth(auth(email: local.email, uid: "google-first"))
    assert_equal "google-first", local.reload.uid

    assert_nil User.from_omniauth(auth(email: local.email, uid: "google-second")),
               "a second Google account must not hijack an already-linked user"
    assert_equal "google-first", local.reload.uid
  end

  test "matches an existing account case-insensitively on email" do
    local = users(:two)
    linked = User.from_omniauth(auth(email: local.email.upcase))

    assert_equal local.id, linked.id
  end

  test "accepts email_verified as the string Google sometimes sends" do
    assert User.from_omniauth(auth(verified: "true"))&.persisted?
  end

  test "returns nil for a malformed auth hash" do
    assert_nil User.from_omniauth(nil)
    assert_nil User.from_omniauth(auth(uid: nil))
    assert_nil User.from_omniauth(auth(email: ""))
  end

  test "falls back to the email local part when Google sends no name" do
    user = User.from_omniauth(auth(name: nil, email: "someone@example.com"))
    assert_equal "someone", user.name
  end

  test "refreshes the avatar on a later sign-in but never the email" do
    user = User.from_omniauth(auth(image: "https://img.test/a.png"))
    original_email = user.email

    User.from_omniauth(auth(image: "https://img.test/b.png", email: "changed@example.com"))

    user.reload
    assert_equal "https://img.test/b.png", user.avatar_url
    assert_equal original_email, user.email, "the email is the account identity; Google must not reassign it"
  end

  test "omniauth_only? reflects whether a password was ever set" do
    user = User.from_omniauth(auth)
    assert_not user.omniauth_only?, "we always set a random password, so a reset is possible"
    assert_nil users(:two).provider
  end
end
