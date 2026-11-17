namespace :admin do
  desc "Make EMAIL an admin: emails a set-password link, or with ADMIN_PASSWORD gives a new account that password (safe to run again)"
  task invite: :environment do
    email = ENV["EMAIL"].to_s.strip
    abort "Usage: bin/rails admin:invite EMAIL=you@example.com [ADMIN_PASSWORD=...]" if email.empty?
    password = ENV["ADMIN_PASSWORD"].presence

    begin
      user = User.invite_admin!(email, password:)
    rescue ArgumentError => e
      abort e.message
    end

    if password.nil?
      puts "Invited #{user.email} as an admin. The set-password email is on its way."
    elsif user.previously_new_record?
      puts "Created #{user.email} as an admin with the password from ADMIN_PASSWORD. No email sent."
    else
      puts "#{user.email} is an admin. They already had an account, so their password is unchanged. No email sent."
    end
  end
end
