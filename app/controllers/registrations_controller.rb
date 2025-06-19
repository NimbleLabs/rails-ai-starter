class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, only: [:create]
  # before_action :check_captcha, only: [:create]

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:email, :password, :password_confirmation, :name)
    end
  end

  # def check_captcha
  #   unless verify_recaptcha
  #     self.resource = resource_class.new sign_up_params
  #     resource.validate # Look for any other validation errors besides Recaptcha
  #     respond_with_navigational(resource) { render :new }
  #   end
  # end

end
