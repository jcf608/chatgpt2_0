require 'sinatra/base'
require 'json'

# Mount API endpoints
require_relative 'api/chats_api'
require_relative 'api/messages_api'
require_relative 'api/prompts_api'
require_relative 'api/audio_api'

class App < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, ENV['PORT'] || 4567
    enable :logging
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

  # Error handling
  error 404 do
    { error: 'Not found' }.to_json
  end

  error 500 do
    { error: 'Internal server error' }.to_json
  end
end

