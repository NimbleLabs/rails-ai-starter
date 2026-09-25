namespace :admin do
  desc "Make EMAIL an admin and email them a link to set their password (safe to run again)"
  task invite: :environment do
    email = ENV["EMAIL"].to_s.strip
    abort "Usage: bin/rails admin:invite EMAIL=you@example.com" if email.empty?

    user = User.invite_admin!(email)
    puts "Invited #{user.email} as an admin. The set-password email is on its way."
  end
end
