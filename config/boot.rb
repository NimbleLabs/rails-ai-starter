ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
# `bin/rails quality` measures coverage, which has to start before any app code
# loads. Configured in .simplecov.
require "simplecov" if ENV["COVERAGE"]
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
