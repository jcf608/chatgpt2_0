# BaseModel - Base class for all file-based models
# Provides common functionality: file operations, validations, error handling

class BaseModel
  attr_accessor :id, :created_at, :updated_at

  def initialize(attributes = {})
    @id = attributes[:id] || generate_id
    @created_at = attributes[:created_at] || Time.now
    @updated_at = attributes[:updated_at] || Time.now
    load_attributes(attributes)
  end

  # Load model from file
  def self.load(id)
    file_path = file_path_for(id)
    return nil unless File.exist?(file_path)

    data = JSON.parse(File.read(file_path))
    new(data.transform_keys(&:to_sym))
  rescue StandardError => e
    raise StandardError, "Failed to load #{self.name} with id: #{id} - #{e.message}"
  end

  # Find model by ID or raise error
  def self.find_or_raise(id)
    record = load(id)
    raise StandardError, "#{self.name} not found with id: #{id}" unless record
    record
  end

  # Save model to file
  def save
    @updated_at = Time.now
    ensure_directory_exists
    File.write(file_path, to_json)
    self
  rescue StandardError => e
    raise StandardError, "Failed to save #{self.class.name} - #{e.message}"
  end

  # Delete model file
  def delete
    File.delete(file_path) if File.exist?(file_path)
    true
  rescue StandardError => e
    raise StandardError, "Failed to delete #{self.class.name} - #{e.message}"
  end

  # Convert to hash
  def to_h
    {
      id: @id,
      created_at: @created_at.iso8601,
      updated_at: @updated_at.iso8601
    }
  end

  # Convert to JSON
  def to_json(*_args)
    JSON.pretty_generate(to_h)
  end

  protected

  def load_attributes(attributes)
    # Override in subclasses to load specific attributes
  end

  def ensure_directory_exists
    dir = File.dirname(file_path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  end

  def file_path
    self.class.file_path_for(@id)
  end

  def self.file_path_for(id)
    # Override in subclasses
    raise NotImplementedError, "#{self.name} must implement file_path_for"
  end

  def self.storage_directory
    # Override in subclasses
    raise NotImplementedError, "#{self.name} must implement storage_directory"
  end

  def generate_id
    SecureRandom.uuid
  end

  require 'json'
  require 'fileutils'
  require 'securerandom'
end
