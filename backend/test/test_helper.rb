ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Disabled to avoid database lock issues with transaction callbacks
    # Can be re-enabled once we add proper database locking mechanisms
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    
    # Helper method to get authentication token for a user
    def auth_token_for(user)
      JwtService.generate_token(user)
    end
    
    # Helper method to set authentication header
    def auth_headers_for(user)
      { "Authorization" => "Bearer #{auth_token_for(user)}" }
    end
  end
end
