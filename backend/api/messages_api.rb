require_relative 'base_api'
require_relative '../services/chat_service'

# MessagesAPI - RESTful API for message management
# Endpoints: GET /api/v1/chats/:id/messages, POST /api/v1/chats/:id/messages

class MessagesAPI < BaseAPI
  # Get all messages for a chat
  get '/api/v1/chats/:id/messages' do
    chat_service = ChatService.new(params[:id])
    messages = chat_service.get_messages
    
    success_response(messages)
  end

  # Add message to chat
  post '/api/v1/chats/:id/messages' do
    data = parse_json_body
    validate_required(data, :role, :content)

    chat_service = ChatService.new(params[:id])
    message = chat_service.add_message(role: data[:role], content: data[:content])
    
    # Ensure message is a hash (not nil) and convert symbol keys to strings for JSON serialization
    if message.nil?
      error_response("Failed to add message: message was nil", code: 'INTERNAL_ERROR', status: 500)
    else
      # Convert symbol keys to string keys for consistent JSON serialization
      message_hash = if message.is_a?(Hash)
        message.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      else
        message
      end
      success_response(message_hash, status: 201)
    end
  rescue StandardError => e
    # Log the full error for debugging
    puts "Error in add message: #{e.class}: #{e.message}"
    puts e.backtrace.first(10).join("\n")
    error_response("Failed to add message: #{e.message}", code: 'INTERNAL_ERROR', status: 500)
  end
end

