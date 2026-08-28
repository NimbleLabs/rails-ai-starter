# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("user")
#  sign_in_count          :integer          default(0), not null
#  slug                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  payment_intent_id      :string
#  stripe_customer_id     :string
#  stripe_subscription_id :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_slug                  (slug)
#
class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :finders ]
  has_subscriptions
  has_secure_token :auth_token

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  enum :role, { user: 0, admin: 1 }

  after_create :on_after_create

  def on_after_create
    UserMailer.with(user: self).welcome_email.deliver_later(wait: 2.seconds)
    subscribe("Newsletter")
  end

  # Find user by auth token for API authentication
  def self.find_by_auth_token(token)
    return nil if token.blank?
    find_by(auth_token: token)
  end

  # Signed in with Google. Returns a persisted user, or nil when the identity
  # cannot be trusted or the record could not be saved.
  #
  # Three cases, in order:
  #
  #   1. We have seen this Google account before (provider + uid) — sign in.
  #   2. A local account already uses this email — link the two, but ONLY if
  #      Google says it verified the address. Linking on an unverified email
  #      would let anyone who can put an address on a Google profile take over
  #      the matching local account.
  #   3. Nobody matches — create an account.
  #
  # New records get a random password because :validatable requires one; the
  # user signs in through Google, and can set a real password later via the
  # normal password-reset flow.
  def self.from_omniauth(auth)
    return nil if auth.blank? || auth.uid.blank? || auth.provider.blank?

    email = auth.info&.email.to_s.downcase.strip
    return nil if email.blank?

    existing = find_by(provider: auth.provider, uid: auth.uid)
    return existing.tap { |user| user.update_omniauth_profile(auth) } if existing

    local = find_by(email: email)
    if local
      return nil unless omniauth_email_verified?(auth)
      # Don't silently move an identity from one Google account to another.
      return nil if local.provider.present? && local.uid != auth.uid

      attrs = { provider: auth.provider, uid: auth.uid }
      attrs[:name] = omniauth_name(auth, email) if local.name.blank?
      attrs[:avatar_url] = auth.info.image if auth.info&.image.present?
      return local.update(attrs) ? local : nil
    end

    return nil unless omniauth_email_verified?(auth)

    user = new(
      email: email,
      name: omniauth_name(auth, email),
      provider: auth.provider,
      uid: auth.uid,
      avatar_url: auth.info&.image,
      password: Devise.friendly_token(32)
    )
    user.save ? user : nil
  end

  # OmniAuth's InfoHash computes `name` from the other fields and falls back to
  # the email address, so a "present" name can still just be the email. Treat
  # that as missing and use the local part instead — it reads better and keeps
  # the FriendlyId slug off the full address.
  def self.omniauth_name(auth, email)
    name = auth.info&.name.to_s.strip
    return email.split("@").first if name.blank? || name.casecmp?(email)

    name
  end

  # Google reports verification in `extra.raw_info.email_verified`, which comes
  # back as a boolean or the string "true" depending on the strategy version.
  def self.omniauth_email_verified?(auth)
    verified = auth.extra&.raw_info&.email_verified
    verified = auth.info&.email_verified if verified.nil?
    ActiveModel::Type::Boolean.new.cast(verified) == true
  end

  # Refresh the bits of the profile Google owns. Never touches the email: that
  # is the account's identity here and changing it on every sign-in would let a
  # Google-side change silently reassign a local account.
  def update_omniauth_profile(auth)
    attrs = {}
    attrs[:name] = self.class.omniauth_name(auth, email) if name.blank?
    attrs[:avatar_url] = auth.info.image if auth.info&.image.present? && avatar_url != auth.info.image
    attrs[:provider] = auth.provider if provider != auth.provider
    attrs[:uid] = auth.uid if uid != auth.uid
    return if attrs.empty?

    update(attrs)
  end

  # True when this account can only be used through an OAuth provider.
  def omniauth_only?
    provider.present? && encrypted_password.blank?
  end
end
