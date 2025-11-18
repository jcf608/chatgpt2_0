require_relative 'base_model'

# AudioOutput model - Stores audio file metadata
# File format: JSON metadata + audio file in data/audio/
# Naming: YYYYMMDD_HHMMSS_[description].mp3

class AudioOutput < BaseModel
  attr_accessor :chat_id, :description, :file_path, :file_size, :duration_seconds

  def initialize(attributes = {})
    super
    @chat_id = attributes[:chat_id]
    @description = attributes[:description] || ''
    @file_path = attributes[:file_path]
    @file_size = attributes[:file_size]
    @duration_seconds = attributes[:duration_seconds]
  end

  # List all audio outputs
  def self.all
    return [] unless Dir.exist?(storage_directory)

    Dir.glob(File.join(storage_directory, '*.json')).map do |file|
      id = File.basename(file, '.json')
      load(id)
    end.compact.sort_by { |audio| audio.created_at }.reverse
  rescue StandardError => e
    raise StandardError, "Failed to list audio outputs: #{e.message}"
  end

  # Find by chat_id
  def self.find_by_chat_id(chat_id)
    all.select { |audio| audio.chat_id == chat_id }
  end

  # Generate filename based on timestamp and description
  def generate_filename
    timestamp = @created_at.strftime('%Y%m%d_%H%M%S')
    desc = @description.gsub(/[^a-zA-Z0-9]/, '_').downcase[0..30]
    "#{timestamp}_#{desc}.mp3"
  end

  # Get full path to audio file
  def audio_file_path
    return nil unless @file_path
    File.join(storage_directory, @file_path)
  end

  # Check if audio file exists
  def audio_file_exists?
    return false unless audio_file_path
    File.exist?(audio_file_path)
  end

  protected

  def load_attributes(attributes)
    @chat_id = attributes[:chat_id]
    @description = attributes[:description] || ''
    @file_path = attributes[:file_path]
    @file_size = attributes[:file_size]
    @duration_seconds = attributes[:duration_seconds]
  end

  def to_h
    super.merge(
      chat_id: @chat_id,
      description: @description,
      file_path: @file_path,
      file_size: @file_size,
      duration_seconds: @duration_seconds,
      audio_file_exists: audio_file_exists?
    )
  end

  def self.file_path_for(id)
    File.join(storage_directory, "#{id}.json")
  end

  def self.storage_directory
    File.join(File.dirname(__FILE__), '..', 'data', 'audio')
  end
end

