require 'sequel'

# Database configuration
DB_CONFIG = {
  development: ENV['DATABASE_URL'] || 'postgresql://localhost/chatgpt2_0_development',
  test: ENV['TEST_DATABASE_URL'] || 'postgresql://localhost/chatgpt2_0_test',
  production: ENV['DATABASE_URL'] || 'postgresql://localhost/chatgpt2_0_production'
}.freeze

# Connect to database
env = ENV['RACK_ENV']&.to_sym || :development
DB = Sequel.connect(DB_CONFIG[env])

# Enable connection pooling
DB.pool.max_connections = 10

# Log SQL queries in development
DB.loggers << Logger.new($stdout) if env == :development

