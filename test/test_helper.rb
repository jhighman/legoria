ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Reset Current attributes between tests
    setup do
      Current.reset if defined?(Current)
    end

    teardown do
      Current.reset if defined?(Current)
    end
  end
end
