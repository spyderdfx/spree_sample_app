ENV['RAILS_ENV'] ||= 'test'

require 'pry-byebug'

require File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/environment', __FILE__)

require 'rspec/rails'
require 'webmock/rspec'

require 'aws-sdk'
# Aws.config[:s3] ||= {}
# Aws.config[:s3].merge!(stub_responses: true)

Dir[
  File.join(File.dirname(__FILE__), 'support', '**', '*.rb')
].each { |f| require f }

require 'redis'
require 'mock_redis'

$redis = MockRedis.new
Redis.current = $redis
Redis::Classy.db = $redis if defined? Redis::Classy
Resque.redis = $redis if defined? Resque

require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/factories'
require 'spree/testing_support/controller_requests'

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.backtrace_exclusion_patterns = []
  config.expose_current_running_example_as :example

  config.include FactoryBot::Syntax::Methods

  config.before(:each) do
    Redis.current.flushdb
  end

  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Devise::TestHelpers, type: :controller
  config.include Warden::Test::Helpers
end
