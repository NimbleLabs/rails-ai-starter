ENV["RAILS_ENV"] ||= "test"

# `bin/rails quality` sets these (see lib/tasks/quality.rake). Coverage usually
# started already in config/boot.rb; requiring it here covers a test run that
# didn't go through it. Configured in .simplecov.
require "simplecov" if ENV["COVERAGE"]
if ENV["QUALITY_TEST_RESULTS"]
  require_relative "support/quality_test_reporter"
  QualityTestReporter.install(ENV["QUALITY_TEST_RESULTS"])
end

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # assert_enqueued_jobs / perform_enqueued_jobs everywhere.
    include ActiveJob::TestHelper

    # Add more helper methods to be used by all tests here...
  end
end

# Devise sign_in / sign_out helpers for integration tests.
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
