require 'net/ssh'

namespace :deploy do
  task :create_dokku_application do
    puts "Creating Dokku application..."
    app_name = 'rails-ai-starter'
    host = ENV['DOKKU_HOST']
    user = ENV['DOKKU_USER']
    password = ENV['DOKKU_PASSWORD']
    
    puts "App name: #{app_name}"

    Net::SSH.start(host, user, password: password) do |ssh|
      ssh.exec!("dokku apps:create #{app_name}")
      ssh.exec!("dokku postgres:create #{app_name}-database")
      ssh.exec!("dokku postgres:link #{app_name}-database #{app_name}")
    end
  end

  task :finish_dokku_setup do

    puts "Finishing Dokku setup..."
    app_name = 'rails-ai-starter'
    host = ENV['DOKKU_HOST']
    user = ENV['DOKKU_USER']
    password = ENV['DOKKU_PASSWORD']
    
    aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
    aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    aws_region = ENV['AWS_REGION'] || 'us-east-1'
    aws_bucket = ENV['AWS_BUCKET']
    email = 'your@email.tld'
    sendgrid_api_key = ENV['SENDGRID_API_KEY']


    Net::SSH.start(host, user, password: password) do |ssh|
        ssh.exec!("dokku domains:add #{app_name} www.#{app_name}.com")
        ssh.exec!("dokku letsencrypt:set #{app_name} email #{email}")
        ssh.exec!("dokku letsencrypt:enable #{app_name}")
        ssh.exec!("dokku buildpacks:add #{app_name} https://github.com/heroku/heroku-buildpack-nodejs.git")
        ssh.exec!("dokku buildpacks:add #{app_name} https://github.com/heroku/heroku-buildpack-ruby.git")
  
        if aws_access_key_id && aws_secret_access_key && aws_bucket
          ssh.exec!("dokku postgres:backup-auth #{app_name}-database #{aws_access_key_id} #{aws_secret_access_key} #{aws_region}")
          ssh.exec!("dokku postgres:backup #{app_name}-database #{aws_bucket}")
          ssh.exec!("dokku postgres:backup-schedule #{app_name}-database \"0 4 * * *\" #{aws_bucket}")
        end

        if sendgrid_api_key 
          ssh.exec!("dokku config:set --no-restart #{app_name} SENDGRID_API_KEY=#{sendgrid_api_key}")
        end
  
      end

  end

end