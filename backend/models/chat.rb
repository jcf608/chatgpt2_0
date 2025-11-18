require_relative 'base_model'

# Chat model - Stores chat conversations with embedded messages
# File format: JSON in data/chats/
# Naming: YYYYMMDD_HHMMSS_dialogue_[N]words.json (generated on save)

class Chat < BaseModel
  attr_accessor :title, :system_prompt_id, :api_provider, :voice, :messages, :metadata

  def initialize(attributes = {})
    super
    @title = attributes[:title]
    @system_prompt_id = attributes[:system_prompt_id]
    @api_provider = attributes[:api_provider] || 'venice'
    @voice = attributes[:voice] || 'echo'
    @messages = attributes[:messages] || []
    @metadata = attributes[:metadata] || {}
  end

  # List all chats
  def self.all
    return [] unless Dir.exist?(storage_directory)

    Dir.glob(File.join(storage_directory, '*.json')).map do |file|
      id = File.basename(file, '.json')
      load(id)
    end.compact.sort_by { |chat| chat.created_at }.reverse
  rescue StandardError => e
    raise StandardError, "Failed to list chats: #{e.message}"
  end

  # Add message to chat
  def add_message(role:, content:)
    validate_message_role(role)
    validate_presence(content, 'content')

    message = {
      id: generate_message_id,
      role: role,
      content: content,
      sequence_number: next_sequence_number,
      created_at: Time.now.iso8601
    }

    @messages << message
    update_metadata
    message
  end

  # Get messages by role
  def get_messages(role: nil)
    if role
      @messages.select { |m| m[:role] == role || m['role'] == role }
    else
      @messages
    end
  end

  # Calculate word count (excluding system messages)
  def word_count
    get_messages.reject { |m| (m[:role] || m['role']) == 'system' }
                .sum { |m| count_words(m[:content] || m['content'] || '') }
  end

  # Generate filename based on timestamp and word count
  def generate_filename
    timestamp = @created_at.strftime('%Y%m%d_%H%M%S')
    words = word_count
    "#{timestamp}_dialogue_#{words}words.json"
  end

  # Override load to handle JSON properly with symbol keys
  def self.load(id)
    file_path = file_path_for(id)
    return nil unless File.exist?(file_path)

    data = JSON.parse(File.read(file_path), symbolize_names: true)
    new(data)
  rescue StandardError => e
    raise StandardError, "Failed to load #{self.name} with id: #{id} - #{e.message}"
  end

  protected

  def load_attributes(attributes)
    @title = attributes[:title]
    @system_prompt_id = attributes[:system_prompt_id]
    @api_provider = attributes[:api_provider] || 'venice'
    @voice = attributes[:voice] || 'echo'
    @messages = (attributes[:messages] || []).map do |msg|
      msg.is_a?(Hash) ? msg.transform_keys(&:to_sym) : msg
    end
    @metadata = attributes[:metadata] || {}
    
    # Parse timestamps if they're strings
    @created_at = parse_time(attributes[:created_at]) if attributes[:created_at]
    @updated_at = parse_time(attributes[:updated_at]) if attributes[:updated_at]
  end

  def to_h
    super.merge(
      title: @title,
      system_prompt_id: @system_prompt_id,
      api_provider: @api_provider,
      voice: @voice,
      messages: @messages,
      metadata: @metadata.merge(word_count: word_count)
    )
  end

  def update_metadata
    @metadata[:word_count] = word_count
    @metadata[:message_count] = @messages.length
    @metadata[:last_activity] = Time.now.iso8601
  end

  def validate_message_role(role)
    unless %w[user assistant system].include?(role)
      raise ArgumentError, "Invalid role: #{role}. Must be 'user', 'assistant', or 'system'"
    end
  end

  def validate_presence(value, field_name)
    raise ArgumentError, "#{field_name} is required" if value.nil? || value.to_s.strip.empty?
  end

  def next_sequence_number
    max_seq = @messages.map { |m| m[:sequence_number] || m['sequence_number'] || 0 }.max || 0
    max_seq + 1
  end

  def generate_message_id
    SecureRandom.hex(8)
  end

  def count_words(text)
    text.split(/\s+/).reject(&:empty?).length
  end

  def parse_time(time_value)
    case time_value
    when Time
      time_value
    when String
      Time.parse(time_value)
    else
      Time.now
    end
  end

  def self.file_path_for(id)
    File.join(storage_directory, "#{id}.json")
  end

  def self.storage_directory
    File.join(File.dirname(__FILE__), '..', 'data', 'chats')
  end
end

