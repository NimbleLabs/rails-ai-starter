class EmailTemplateMailer < ApplicationMailer
  has_history user: -> { params[:user] }


  def email_template_email
    @email_template = params[:email_template]
    @subject = @email_template.subject # TODO: handle template variables!
    @user = params[:user] # User or Contact
    bootstrap_mail(to: @user.email, subject: @subject)
  end

end
