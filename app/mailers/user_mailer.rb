class UserMailer < ApplicationMailer

  def welcome_email
    @user = params[:user]
    bootstrap_mail(to: @user.email, subject: 'Welcome!')
  end

end
