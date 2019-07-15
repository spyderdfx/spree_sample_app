ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

require 'dotenv'

rails_env = ENV.fetch('RAILS_ENV', 'development')
env_files = %W(.env .env.#{rails_env} .env.local).each_with_object([]) do |env_file, memo|
  file_path = File.expand_path("../../#{env_file}", __FILE__)
  memo << file_path if File.exist?(file_path)
end
Dotenv.overload(*env_files)
