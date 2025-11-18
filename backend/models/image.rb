require_relative 'base_model'

# Image model - Stores image file metadata
# File format: JSON metadata + image file in data/images/
# Naming: YYYYMMDD_HHMMSS_[description].png

class Image < BaseModel
  attr_accessor :chat_id, :prompt_id, :description, :file_path, :file_size, :width, :height

  def initialize(attributes = {})
    super
    @chat_id = attributes[:chat_id]
    @prompt_id = attributes[:prompt_id]
    @description = attributes[:description] || ''
    @file_path = attributes[:file_path]
    @file_size = attributes[:file_size]
    @width = attributes[:width]
    @height = attributes[:height]
  end

  # List all images
  def self.all
    return [] unless Dir.exist?(storage_directory)

    Dir.glob(File.join(storage_directory, '*.json')).map do |file|
      id = File.basename(file, '.json')
      load(id)
    end.compact.sort_by { |image| image.created_at }.reverse
  rescue StandardError => e
    raise StandardError, "Failed to list images: #{e.message}"
  end

  # Find by chat_id
  def self.find_by_chat_id(chat_id)
    all.select { |image| image.chat_id == chat_id }
  end

  # Generate filename based on timestamp and description
  def generate_filename
    timestamp = @created_at.strftime('%Y%m%d_%H%M%S')
    desc = @description.gsub(/[^a-zA-Z0-9]/, '_').downcase[0..30]
    "#{timestamp}_#{desc}.png"
  end

  # Get full path to image file
  def image_file_path
    return nil unless @file_path
    File.join(storage_directory, @file_path)
  end

  # Check if image file exists
  def image_file_exists?
    return false unless image_file_path
    File.exist?(image_file_path)
  end

  protected

  def load_attributes(attributes)
    @chat_id = attributes[:chat_id]
    @prompt_id = attributes[:prompt_id]
    @description = attributes[:description] || ''
    @file_path = attributes[:file_path]
    @file_size = attributes[:file_size]
    @width = attributes[:width]
    @height = attributes[:height]
  end

  def to_h
    super.merge(
      chat_id: @chat_id,
      prompt_id: @prompt_id,
      description: @description,
      file_path: @file_path,
      file_size: @file_size,
      width: @width,
      height: @height,
      image_file_exists: image_file_exists?
    )
  end

  def self.file_path_for(id)
    File.join(storage_directory, "#{id}.json")
  end

  def self.storage_directory
    File.join(File.dirname(__FILE__), '..', 'data', 'images')
  end
end

