class EmailTemplateMailerPreview < ActionMailer::Preview

  def email_template_email
    EmailTemplateMailer.with(user: User.first, email_template: EmailTemplate.first).email_template_email
  end
end