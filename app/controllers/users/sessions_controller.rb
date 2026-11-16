# Email-and-password sign-in. Devise does the work; this records that it happened.
#
# Devise only yields once the password checked out (a wrong one never reaches the block), and a
# remember-me cookie signs people in without coming through here, so this counts real sign-ins.
class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      Analytics.track(Analytics::SIGN_IN, user: user, controller: self, properties: { provider: "email" })
    end
  end
end
