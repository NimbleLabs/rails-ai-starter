# Coverage for `bin/rails quality` (see lib/tasks/quality.rake). SimpleCov loads
# this file itself on `require "simplecov"`, which config/boot.rb does first
# thing whenever COVERAGE is set: Rails' test commands can boot the app (and run
# its initializers) before test_helper loads, and files loaded before coverage
# starts are never measured.
SimpleCov.start "rails" do
  enable_coverage :branch
  group "Services", "app/services"
  # Starting at boot also catches the Rakefile and lib/tasks loading; they've
  # never been part of the measured code.
  skip %r{\A(Rakefile|lib/tasks/)}
  formats :html, :json
  source_in_json false
end
