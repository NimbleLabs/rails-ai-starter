class LogMailer < ApplicationMailer
  def log_alert
    @log = params[:log]
    @app_name = LogNotifier::APP_NAME
    @admin_url = LogNotifier.new(@log, nil).admin_url
    mail(to: params[:to], subject: "[#{@app_name}] #{@log.level.upcase}: #{@log.title.truncate(120)}")
  end
end
