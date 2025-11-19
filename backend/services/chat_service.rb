require_relative 'base_service'
require_relative '../models/chat'

# ChatService - Manages chat conversations
# Handles creating chats, adding messages, retrieving history

class ChatService < BaseService
  def initialize(chat_id = nil)
    @chat_id = chat_id
  end

  # Create a new chat
  def create(title: nil, system_prompt_id: nil, api_provider: 'venice', voice: 'echo')
    validate_presence(api_provider, 'api_provider')

    chat = Chat.new(
      title: title || generate_default_title,
      system_prompt_id: system_prompt_id,
      api_provider: api_provider,
      voice: voice
    )

    chat.save
    @chat_id = chat.id
    chat
  rescue StandardError => e
    handle_error(e, operation: 'Create chat')
  end

  # Load chat
  def load_chat
    validate_presence(@chat_id, 'chat_id')
    Chat.find_or_raise(@chat_id)
  end

  # Add a message to the chat
  def add_message(role:, content:)
    validate_presence(@chat_id, 'chat_id')
    
    # Ensure content is a non-empty string
    content_str = content.to_s.strip
    if content_str.empty?
      raise ArgumentError, "content is required and cannot be empty"
    end
    
    chat = load_chat
    message = chat.add_message(role: role, content: content_str)
    chat.save
    message
  rescue StandardError => e
    handle_error(e, operation: 'Add message')
  end

  # Get all messages for the chat
  def get_messages
    validate_presence(@chat_id, 'chat_id')
    chat = load_chat
    chat.get_messages
  rescue StandardError => e
    handle_error(e, operation: 'Get messages')
  end

  # Clear conversation (remove all messages except system)
  def clear_conversation
    validate_presence(@chat_id, 'chat_id')
    chat = load_chat
    chat.messages = chat.get_messages(role: 'system')
    chat.save
    true
  rescue StandardError => e
    handle_error(e, operation: 'Clear conversation')
  end

  # Get word count for the chat
  def word_count
    validate_presence(@chat_id, 'chat_id')
    chat = load_chat
    chat.word_count
  rescue StandardError => e
    handle_error(e, operation: 'Get word count')
  end

  private

  def generate_default_title
    "Chat #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  end
end

