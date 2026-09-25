class UserMailer < ApplicationMailer

  def welcome_email
    @user = params[:user]
    bootstrap_mail(to: @user.email, subject: 'Welcome!')
  end

  # From User.invite_admin!: a link to set the password, then the admin.
  def admin_invite
    @user = params[:user]
    @app_name = ENV.fetch("APP_NAME", "Starter")
    @set_password_url = edit_user_password_url(reset_password_token: params[:token])
    @admin_url = admin_url
    @hours = (Devise.reset_password_within / 1.hour).round
    mail(to: @user.email, subject: "Your #{@app_name} admin account is ready")
  end

end
