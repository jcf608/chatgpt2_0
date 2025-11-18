require 'bundler/setup'
Bundler.require

# Load environment variables
require 'dotenv'
Dotenv.load

# Set up environment
ENV['RACK_ENV'] ||= 'development'

# Database configuration
require_relative 'database'

# Load application files
Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].each { |f| require f }
Dir[File.join(__dir__, '..', 'models', '**', '*.rb')].each { |f| require f }
Dir[File.join(__dir__, '..', 'services', '**', '*.rb')].each { |f| require f }
Dir[File.join(__dir__, '..', 'api', '**', '*.rb')].each { |f| require f }

