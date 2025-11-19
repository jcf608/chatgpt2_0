require 'sinatra/base'
require 'json'
require 'fileutils'

# Mount API endpoints
require_relative 'api/chats_api'
require_relative 'api/messages_api'
require_relative 'api/prompts_api'
require_relative 'api/audio_api'

class App < Sinatra::Base
  # Unconditional log write on server start
  begin
    log_file = File.join(File.dirname(__FILE__), '..', 'logs', 'backend.log')
    FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
    File.open(log_file, 'a') do |f|
      f.puts "=" * 80
      f.puts "[#{Time.now.iso8601}] [INFO] ========================================="
      f.puts "[#{Time.now.iso8601}] [INFO] SERVER STARTED - LOGGING TEST"
      f.puts "[#{Time.now.iso8601}] [INFO] Log file path: #{log_file}"
      f.puts "[#{Time.now.iso8601}] [INFO] File writable: #{File.writable?(log_file)}"
      f.puts "[#{Time.now.iso8601}] [INFO] ========================================="
      f.puts "=" * 80
    end
  rescue => e
    # If this fails, we have a serious problem
    STDERR.puts "CRITICAL: Could not write to log file: #{e.message}"
    STDERR.puts "Log file path attempted: #{log_file rescue 'unknown'}"
  end
  
  configure do
    set :bind, '0.0.0.0'
    set :port, ENV['PORT'] || 4567
    enable :logging
    disable :show_exceptions  # Let BaseAPI error handlers return JSON
    disable :raise_errors      # Don't raise errors to Rack, handle them ourselves
  end

  # CORS configuration
  use Rack::Cors do
    allow do
      origins '*'
      resource '*',
               headers: :any,
               methods: [:get, :post, :put, :delete, :options]
    end
  end

  # Health check
  get '/' do
    { status: 'ok', message: 'ChatGPT v2.0 API' }.to_json
  end

  # Mount API endpoints
  use ChatsAPI
  use MessagesAPI
  use PromptsAPI
  use AudioAPI

  # Error handling - let BaseAPI handle errors
  # (BaseAPI error handlers will catch errors from mounted APIs)
end

