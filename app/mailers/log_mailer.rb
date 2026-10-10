class LogMailer < ApplicationMailer
  def log_alert
    @log = params[:log]
    @admin_url = LogNotifier.new(@log, nil).admin_url
    mail(to: params[:to], subject: "[#{AppConfig.current.name}] #{@log.level.upcase}: #{@log.title.truncate(120)}")
  end
end
