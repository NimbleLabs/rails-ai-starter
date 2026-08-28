class RegistrationsController < Devise::RegistrationsController
  include RecaptchaProtection

  before_action :configure_permitted_parameters, only: [ :create ]
  before_action :check_signup_captcha, only: [ :create ]

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:email, :password, :password_confirmation, :name)
    end
  end

  # Rejects the sign-up before Devise builds the user. `check_recaptcha` adds
  # the failure to the resource's errors so it renders with the rest of the
  # form's validation messages rather than as a bare flash.
  def check_signup_captcha
    self.resource = resource_class.new(sign_up_params)
    return if check_recaptcha(action: "signup", model: resource)

    resource.validate # surface any other problems in the same render
    respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
  end
end
