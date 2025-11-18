require_relative 'base_service'

# ChatService - Manages chat conversations
# Handles creating chats, adding messages, retrieving history

class ChatService < BaseService
  def initialize(chat_id = nil)
    @chat_id = chat_id
  end

  # Create a new chat
  def create(title: nil, system_prompt_id: nil, api_provider: 'venice', voice: 'echo')
    validate_presence(api_provider, 'api_provider')

    chat_data = {
      title: title || generate_default_title,
      system_prompt_id: system_prompt_id,
      api_provider: api_provider,
      voice: voice,
      created_at: Time.now,
      updated_at: Time.now
    }

    # TODO: Create chat record when Chat model is implemented
    # chat = Chat.create(chat_data)
    # @chat_id = chat.id
    # chat

    # Placeholder return
    { id: 1, **chat_data }
  rescue StandardError => e
    handle_error(e, operation: 'Create chat')
  end

  # Add a message to the chat
  def add_message(role:, content:)
    validate_presence(@chat_id, 'chat_id')
    validate_presence(role, 'role')
    validate_presence(content, 'content')

    unless %w[user assistant system].include?(role)
      raise ArgumentError, "Invalid role: #{role}. Must be 'user', 'assistant', or 'system'"
    end

    message_data = {
      chat_id: @chat_id,
      role: role,
      content: content,
      sequence_number: next_sequence_number,
      created_at: Time.now
    }

    # TODO: Create message record when Message model is implemented
    # Message.create(message_data)

    # Placeholder return
    { id: 1, **message_data }
  rescue StandardError => e
    handle_error(e, operation: 'Add message')
  end

  # Get all messages for the chat
  def get_messages
    validate_presence(@chat_id, 'chat_id')

    # TODO: Retrieve messages when Message model is implemented
    # Message.where(chat_id: @chat_id).order(:sequence_number).all

    # Placeholder return
    []
  rescue StandardError => e
    handle_error(e, operation: 'Get messages')
  end

  # Clear conversation (remove all messages except system)
  def clear_conversation
    validate_presence(@chat_id, 'chat_id')

    # TODO: Delete non-system messages when Message model is implemented
    # Message.where(chat_id: @chat_id).where { role != 'system' }.delete

    true
  rescue StandardError => e
    handle_error(e, operation: 'Clear conversation')
  end

  # Get word count for the chat
  def word_count
    messages = get_messages
    messages.reject { |m| m[:role] == 'system' }
            .sum { |m| count_words(m[:content]) }
  end

  private

  def generate_default_title
    "Chat #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  end

  def next_sequence_number
    # TODO: Get max sequence number when Message model is implemented
    # max_seq = Message.where(chat_id: @chat_id).max(:sequence_number) || 0
    # max_seq + 1

    # Placeholder
    1
  end

  def count_words(text)
    text.split(/\s+/).reject(&:empty?).length
  end
end

