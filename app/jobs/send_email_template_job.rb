class SendEmailTemplateJob < ApplicationJob
  queue_as :default
  
  retry_on ActiveRecord::RecordNotFound, wait: 5.seconds, attempts: 3
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(email_template_id)
    puts "Running SendEmailTemplateJob for template ID #{email_template_id}"
    email_template = EmailTemplate.find(email_template_id)
    recipients = get_recipients(email_template.send_group)
    Rails.logger.info "Starting to send email template #{email_template_id} to #{email_template.send_group}"
    sent_count = 0
    already_sent_count = 0
    error_count = 0

    recipients.find_each do |recipient|
      begin
        # TODO: check to ensure email with subject was not sent to this recipient already
        if email_template.already_sent?(recipient)
          already_sent_count += 1
          next
        end

        puts "Sending email to #{recipient.email}"
        EmailTemplateMailer.with(email_template: email_template, user: recipient).email_template_email.deliver_now
        sent_count += 1
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "Failed to send email to #{recipient.email}: #{e.message}"
      end
    end

    #SlackService.system_alert_service.email_sent_event(email_template.subject, sent_count, already_sent_count, error_count)
  end

  private

  def get_recipients(send_group)
    User.subscribed(send_group)
    # TODO: support contacts too?
    # case send_group
    # when "Users"
    #   User.where.not(email: nil)
    # when "Equipment Finance"
    #   Contact.where(source: "Equipment Finance")
    # else
    #   raise ArgumentError, "Invalid send_group: #{send_group}"
    # end
  end
end 