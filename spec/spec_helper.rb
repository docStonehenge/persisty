require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require "bundler/setup"
require "persisty"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Persisty::Matchers::FieldDefinedMatchers
end

require 'support/connection_definitions'

Dir["spec/support/**/*.rb"].each { |f| load f }
