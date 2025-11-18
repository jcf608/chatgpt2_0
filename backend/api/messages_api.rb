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

    success_response(message, status: 201)
  end
end

