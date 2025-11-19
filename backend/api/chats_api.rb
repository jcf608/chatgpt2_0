require_relative 'base_api'
require_relative '../models/chat'
require_relative '../services/chat_service'
require_relative '../services/ai_service'
require_relative '../services/prompt_service'
require 'fileutils'

# ChatsAPI - RESTful API for chat management
# Endpoints: GET /api/v1/chats, POST /api/v1/chats, GET /api/v1/chats/:id, DELETE /api/v1/chats/:id

class ChatsAPI < BaseAPI
  # Helper method to safely log to file (inherited from BaseAPI, but ensure it's available)
  def safe_log(message, level = 'INFO')
    begin
      log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
      FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
      File.open(log_file, 'a') do |f|
        f.puts "[#{Time.now.iso8601}] [#{level}] #{message}"
      end
    rescue => e
      # If even file logging fails, silently continue
    end
  end
  
  # Log all requests
  before do
    begin
      log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
      FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
      File.open(log_file, 'a') do |f|
        f.puts "[#{Time.now.iso8601}] [INFO] REQUEST: #{request.request_method} #{request.path_info}"
        f.puts "[#{Time.now.iso8601}] [INFO] Params: #{params.inspect}"
      end
    rescue => e
      # Ignore
    end
  end
  
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
    # Log immediately at the start - even before any processing
    begin
      log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
      FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
      File.open(log_file, 'a') do |f|
        f.puts "[#{Time.now.iso8601}] [INFO] === SEND MESSAGE START ==="
        f.puts "[#{Time.now.iso8601}] [INFO] Chat ID: #{params[:id]}"
        f.puts "[#{Time.now.iso8601}] [INFO] Request method: #{request.request_method}"
        f.puts "[#{Time.now.iso8601}] [INFO] Request path: #{request.path_info}"
      end
    rescue => log_err
      # Ignore logging errors
    end
    
    safe_log("=== SEND MESSAGE START ===")
    safe_log("Chat ID: #{params[:id]}")
    begin
      data = parse_json_body
      safe_log("Parsed data: #{data.inspect}")
      validate_required(data, :content)
      safe_log("Validation passed")

      chat_service = ChatService.new(params[:id])
      safe_log("ChatService created")
      chat = chat_service.load_chat
      safe_log("Chat loaded: #{chat.id}")

      # Validate and add user message
      user_content = data[:content].to_s.strip
      safe_log("User content: #{user_content.inspect}")
      if user_content.empty?
        safe_log("ERROR: User content is empty!", 'ERROR')
        halt 400, error_response("Message content cannot be empty", code: 'VALIDATION_ERROR', status: 400)
      end
      safe_log("Adding user message...")
      chat_service.add_message(role: 'user', content: user_content)
      safe_log("User message added")

      # Get all messages for AI - just like the old code, send all messages including system prompt
      # Sort by sequence_number to ensure correct chronological order
      safe_log("Getting messages...")
      all_messages = chat_service.get_messages
      safe_log("Got #{all_messages.length} messages")
      
      # Sort by sequence_number to ensure chronological order (system, user, assistant, user, assistant, ...)
      sorted_messages = all_messages.sort_by { |msg| msg[:sequence_number] || msg['sequence_number'] || 0 }
      
      messages = sorted_messages.map do |msg|
        {
          role: msg[:role] || msg['role'],
          content: msg[:content] || msg['content']
        }
      end

      # Send to AI
      safe_log("Creating AI service with provider: #{chat.api_provider}")
      begin
        ai_service = AIService.new(provider: chat.api_provider)
        safe_log("Sending to AI...")
        safe_log("Messages being sent: #{messages.inspect[0..500]}")
        response = ai_service.send_message(messages)
        safe_log("AI response received: #{response.keys.inspect}")
      rescue => ai_service_err
        safe_log("ERROR in AI service call: #{ai_service_err.class}: #{ai_service_err.message}", 'ERROR')
        safe_log("  Backtrace: #{ai_service_err.backtrace.first(10).join("\n")}", 'ERROR')
        raise ai_service_err
      end
      
      # Log full Venice response
      safe_log("=" * 80)
      safe_log("VENICE RESPONSE IN CHATS_API:")
      begin
        require 'json'
        safe_log(JSON.pretty_generate(response))
      rescue => e
        safe_log("Could not pretty print: #{e.message}")
        safe_log(response.inspect)
      end
      safe_log("=" * 80)

      if response['error']
        error_data = response['error'].is_a?(Hash) ? response['error'] : { 'message' => response['error'].to_s }
        error_msg = error_data['message'] || 'An error occurred'
        
        # Check if it's a Venice.ai server error with HTML content
        if error_data['is_html'] && error_data['html_content']
          halt 503, error_response(
            error_msg,
            code: 'AI_SERVICE_ERROR',
            details: { html_content: error_data['html_content'] },
            status: 503
          )
        elsif error_msg.include?('500') || error_msg.include?('Internal server error')
          halt 503, error_response(
            "Venice.ai API is currently experiencing issues. Please try again in a moment. Error: #{error_msg}",
            code: 'AI_SERVICE_ERROR',
            status: 503
          )
        else
          halt 500, error_response(error_msg, code: 'AI_ERROR', status: 500)
        end
      elsif response['choices'] && response['choices'][0] && response['choices'][0]['message']
        message_obj = response['choices'][0]['message']
        
        # Log response structure for debugging
        safe_log("Response structure check:")
        safe_log("  response['choices'] exists: #{!response['choices'].nil?}")
        safe_log("  response['choices'][0] exists: #{!response['choices'][0].nil?}") if response['choices']
        safe_log("  response['choices'][0]['message'] exists: #{!response['choices'][0]['message'].nil?}") if response['choices'] && response['choices'][0]
        
        if message_obj.nil?
          safe_log("ERROR: message_obj is nil!", 'ERROR')
          halt 500, {
            success: false,
            error: {
              message: "Venice response has no message object",
              code: 'AI_ERROR',
              details: { response_structure: response.keys.inspect }
            },
            timestamp: Time.now.iso8601
          }.to_json
        end
        
        ai_content = message_obj['content']
        
        # If content is empty, try reasoning_content as fallback (Venice.ai sometimes uses this)
        if (ai_content.nil? || ai_content.to_s.strip.empty?) && message_obj['reasoning_content']
          safe_log("Content is empty, using reasoning_content as fallback")
          ai_content = message_obj['reasoning_content']
        end
        
        # If still empty, try combining content and reasoning_content
        if (ai_content.nil? || ai_content.to_s.strip.empty?)
          content_part = message_obj['content'].to_s.strip
          reasoning_part = message_obj['reasoning_content'].to_s.strip if message_obj['reasoning_content']
          if !content_part.empty? && !reasoning_part.nil? && !reasoning_part.empty?
            ai_content = "#{content_part}\n\n#{reasoning_part}"
            safe_log("Combined content and reasoning_content")
          elsif !reasoning_part.nil? && !reasoning_part.empty?
            ai_content = reasoning_part
            safe_log("Using reasoning_content only")
          end
        end
        
        # Debug logging
        safe_log("AI Response Debug:")
        safe_log("  response keys: #{response.keys.inspect}")
        safe_log("  choices[0] keys: #{response['choices'][0].keys.inspect if response['choices'][0]}")
        safe_log("  message keys: #{message_obj.keys.inspect}")
        safe_log("  ai_content: #{ai_content.inspect}")
        safe_log("  ai_content class: #{ai_content.class}")
        safe_log("  ai_content to_s: #{ai_content.to_s.inspect}")
        
        # Validate AI content is not empty
        if ai_content.nil? || ai_content.to_s.strip.empty?
          available_keys = message_obj.keys.join(', ')
          content_val = message_obj['content']
          reasoning_val = message_obj['reasoning_content']
          
          # Log to file directly as backup
          begin
            log_data = {
              timestamp: Time.now.iso8601,
              available_keys: available_keys,
              content: content_val,
              reasoning_content: reasoning_val ? reasoning_val[0..500] : nil,
              full_message_obj: message_obj,
              full_response: response
            }
            log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'empty_content_error.json')
            FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
            require 'json'
            File.write(log_file, JSON.pretty_generate(log_data))
            safe_log("Error details written to: #{log_file}")
          rescue => file_err
            safe_log("Could not write error log: #{file_err.message}", 'ERROR')
          end
          
          error_msg = "Venice.ai returned an empty response. The AI service did not generate any content. Please try again or check logs/empty_content_error.json for details."
          
          safe_log("ERROR: AI content is empty or nil!", 'ERROR')
          safe_log("  Available keys: #{available_keys}", 'ERROR')
          safe_log("  Content: #{content_val.inspect}", 'ERROR')
          safe_log("  Reasoning: #{reasoning_val ? reasoning_val[0..100].inspect : 'nil'}", 'ERROR')
          
          # Log the error details before raising
          safe_log("About to raise empty response error", 'ERROR')
          safe_log("  Error message: #{error_msg}", 'ERROR')
          
          # Raise a custom exception so the error handler can catch it properly
          venice_id = begin
            response['id']
          rescue => id_err
            safe_log("Could not get venice_id: #{id_err.message}", 'ERROR')
            nil
          end
          
          # Create a custom error with all the details
          empty_response_error = StandardError.new(error_msg)
          empty_response_error.define_singleton_method(:venice_response_id) { venice_id }
          empty_response_error.define_singleton_method(:available_keys) { available_keys }
          empty_response_error.define_singleton_method(:has_content) { !content_val.nil? && !content_val.to_s.empty? }
          empty_response_error.define_singleton_method(:has_reasoning) { !reasoning_val.nil? && !reasoning_val.to_s.empty? }
          empty_response_error.define_singleton_method(:error_code) { 'AI_EMPTY_RESPONSE' }
          
          safe_log("Raising empty_response_error: #{empty_response_error.class}: #{empty_response_error.message}", 'ERROR')
          raise empty_response_error
        end
        
        # Add AI response to chat (ensure content is a non-empty string)
        final_content = ai_content.to_s.strip
        if final_content.empty?
          safe_log("ERROR: Final content is empty after to_s.strip!", 'ERROR')
          halt 500, error_response("AI returned empty response after processing", code: 'AI_ERROR', status: 500)
        end
        message = chat_service.add_message(role: 'assistant', content: final_content)
        
        success_response({
          message: message,
          ai_response: ai_content,
          chat: chat_service.load_chat.to_h
        })
      else
        safe_log("ERROR: Unexpected AI response format", 'ERROR')
        halt 500, error_response("Unexpected AI response format: #{response.inspect}", code: 'AI_ERROR', status: 500)
      end
      rescue StandardError => e
        # Log the full error for debugging
        error_msg = "Error in send message: #{e.class}: #{e.message}"
        safe_log("=== ERROR CAUGHT IN CHATS_API ===", 'ERROR')
        safe_log(error_msg, 'ERROR')
        safe_log(e.backtrace.first(15).join("\n"), 'ERROR')
        safe_log("=== END ERROR ===", 'ERROR')
        
        # Re-raise the exception so the Sinatra error handlers can process it
        # This ensures env['sinatra.error'] is properly set
        raise e
      end
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

