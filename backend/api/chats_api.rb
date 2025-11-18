require_relative 'base_api'
require_relative '../models/chat'
require_relative '../services/chat_service'
require_relative '../services/ai_service'
require_relative '../services/prompt_service'

# ChatsAPI - RESTful API for chat management
# Endpoints: GET /api/v1/chats, POST /api/v1/chats, GET /api/v1/chats/:id, DELETE /api/v1/chats/:id

class ChatsAPI < BaseAPI
  # List all chats
  get '/api/v1/chats' do
    chats = Chat.all
    success_response(chats.map(&:to_h))
  end

  # Get chat by ID
  get '/api/v1/chats/:id' do
    chat = Chat.find_or_raise(params[:id])
    success_response(chat.to_h)
  end

  # Create new chat
  post '/api/v1/chats' do
    data = parse_json_body
    validate_required(data, :api_provider)

    service = ChatService.new
    chat = service.create(
      title: data[:title],
      system_prompt_id: data[:system_prompt_id],
      api_provider: data[:api_provider] || 'venice',
      voice: data[:voice] || 'echo'
    )

    success_response(chat.to_h, status: 201)
  end

  # Delete chat
  delete '/api/v1/chats/:id' do
    chat = Chat.find_or_raise(params[:id])
    chat.delete
    success_response({ message: 'Chat deleted successfully' })
  end

  # Send message to AI
  post '/api/v1/chats/:id/send' do
    data = parse_json_body
    validate_required(data, :content)

    chat_service = ChatService.new(params[:id])
    chat = chat_service.load_chat

    # Add user message
    chat_service.add_message(role: 'user', content: data[:content])

    # Get all messages for AI, sorted so system messages come first
    all_messages = chat_service.get_messages
    messages = all_messages.sort_by do |msg|
      role = msg[:role] || msg['role']
      seq = msg[:sequence_number] || msg['sequence_number'] || 0
      # System messages first (0), then user/assistant (1, 2)
      role_priority = role == 'system' ? 0 : (role == 'user' ? 1 : 2)
      [role_priority, seq]
    end.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end

    # Send to AI
    ai_service = AIService.new(provider: chat.api_provider)
    response = ai_service.send_message(messages)

    if response['error']
      error_msg = response['error'].is_a?(Hash) ? response['error']['message'] : response['error'].to_s
      error_response(error_msg, code: 'AI_ERROR', status: 500)
    elsif response['choices'] && response['choices'][0] && response['choices'][0]['message']
      ai_content = response['choices'][0]['message']['content']
      
      # Add AI response to chat
      message = chat_service.add_message(role: 'assistant', content: ai_content)
      
      success_response({
        message: message,
        ai_response: ai_content,
        chat: chat_service.load_chat.to_h
      })
    else
      error_response("Unexpected AI response format: #{response.inspect}", code: 'AI_ERROR', status: 500)
    end
  rescue StandardError => e
    # Log the full error for debugging
    puts "Error in send message: #{e.class}: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    error_response("Failed to send message: #{e.message}", code: 'INTERNAL_ERROR', status: 500)
  end

  # Extended dialogue generation
  post '/api/v1/chats/:id/extend' do
    data = parse_json_body
    target_words = data[:target_words] || 1000

    chat_service = ChatService.new(params[:id])
    chat = chat_service.load_chat

    messages = chat_service.get_messages.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end

    ai_service = AIService.new(provider: chat.api_provider)
    
    result = ai_service.generate_extended_dialogue(
      messages,
      target_words: target_words.to_i,
      progress_callback: nil # TODO: Add streaming/progress callbacks
    )

    if result.is_a?(Hash) && result[:error]
      error_response(result[:error], code: 'AI_ERROR', status: 500)
    else
      # Add generated segments to chat
      segments = result[:segments] || []
      segments.each do |segment_content|
        chat_service.add_message(role: 'assistant', content: segment_content) if segment_content
      end

      success_response({
        segments: segments,
        total_words: result[:total_words],
        segment_count: result[:segment_count],
        chat: chat_service.load_chat.to_h
      })
    end
  end

  # Continue conversation
  post '/api/v1/chats/:id/continue' do
    data = parse_json_body
    additional_words = data[:additional_words] || 500
    user_prompt = data[:prompt]

    chat_service = ChatService.new(params[:id])
    chat = chat_service.load_chat

    messages = chat_service.get_messages.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end

    # Add continuation prompt if provided
    if user_prompt
      messages << { role: 'user', content: user_prompt }
    end

    ai_service = AIService.new(provider: chat.api_provider)
    
    result = ai_service.generate_extended_dialogue(
      messages,
      target_words: chat_service.word_count + additional_words.to_i,
      progress_callback: nil
    )

    if result.is_a?(Hash) && result[:error]
      error_response(result[:error], code: 'AI_ERROR', status: 500)
    else
      # Add generated segments to chat
      segments = result[:segments] || []
      segments.each do |segment_content|
        chat_service.add_message(role: 'assistant', content: segment_content) if segment_content
      end

      success_response({
        segments: segments,
        total_words: result[:total_words],
        segment_count: result[:segment_count],
        chat: chat_service.load_chat.to_h
      })
    end
  end

  # Get word count
  get '/api/v1/chats/:id/word-count' do
    chat_service = ChatService.new(params[:id])
    word_count = chat_service.word_count
    
    success_response({
      chat_id: params[:id],
      word_count: word_count
    })
  end

  # Generate prompt synopsis
  post '/api/v1/chats/:id/synopsis' do
    chat_service = ChatService.new(params[:id])
    messages = chat_service.get_messages

    prompt_service = PromptService.new
    synopsis = prompt_service.generate_synopsis(messages)

    if synopsis
      success_response({ synopsis: synopsis })
    else
      error_response('Failed to generate synopsis', code: 'SYNOPSIS_ERROR', status: 500)
    end
  end

  # Start chat with opening line
  post '/api/v1/chats/:id/opening' do
    data = parse_json_body
    prompt_name = data[:prompt_name]
    
    raise ArgumentError, 'prompt_name is required' unless prompt_name

    prompt_service = PromptService.new
    opening_line = prompt_service.random_opening_line(prompt_name)

    raise StandardError, "No opening lines found for prompt: #{prompt_name}" unless opening_line

    chat_service = ChatService.new(params[:id])
    message = chat_service.add_message(role: 'user', content: opening_line)

    success_response({
      message: message,
      opening_line: opening_line
    })
  end
end

