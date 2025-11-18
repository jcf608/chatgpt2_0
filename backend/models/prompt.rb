require_relative 'base_model'

# Prompt model - Stores user prompts in .prompt file format
# File format: Plain text in data/prompts/
# Naming: [name].prompt

class Prompt < BaseModel
  attr_accessor :name, :content

  def initialize(attributes = {})
    super
    @name = attributes[:name] || attributes[:id]
    @content = attributes[:content] || ''
  end

  # List all prompts
  def self.all
    return [] unless Dir.exist?(storage_directory)

    prompts = []
    Dir.glob(File.join(storage_directory, '*.prompt')).each do |file|
      name = File.basename(file, '.prompt')
      begin
        prompt = load(name)
        prompts << prompt if prompt
      rescue StandardError => e
        # Log error but continue loading other prompts
        puts "Warning: Failed to load prompt '#{name}': #{e.message}"
      end
    end
    prompts
  rescue StandardError => e
    raise StandardError, "Failed to list prompts: #{e.message}"
  end

  # Find by name
  def self.find_by_name(name)
    load(name)
  end

  # Override load to read .prompt file
  def self.load(name)
    file_path = file_path_for(name)
    return nil unless File.exist?(file_path)

    # Read file with UTF-8 encoding, handling invalid bytes gracefully
    content = File.read(file_path, encoding: 'UTF-8:UTF-8').strip
    new(id: name, name: name, content: content, created_at: File.mtime(file_path), updated_at: File.mtime(file_path))
  rescue Encoding::InvalidByteSequenceError => e
    # Try reading with binary mode and force encoding
    content = File.binread(file_path).force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace).strip
    new(id: name, name: name, content: content, created_at: File.mtime(file_path), updated_at: File.mtime(file_path))
  rescue StandardError => e
    raise StandardError, "Failed to load Prompt with name: #{name} - #{e.message}"
  end

  # Override save to write .prompt file
  def save
    @updated_at = Time.now
    ensure_directory_exists
    
    # Use name as ID if ID is not set
    @id = @name if @id.nil?
    @name = @id if @name.nil?
    
    # Write file with UTF-8 encoding
    File.write(file_path, @content, encoding: 'UTF-8')
    self
  rescue StandardError => e
    raise StandardError, "Failed to save Prompt - #{e.message}"
  end

  # Override delete
  def delete
    File.delete(file_path) if File.exist?(file_path)
    true
  rescue StandardError => e
    raise StandardError, "Failed to delete Prompt - #{e.message}"
  end

  # Get preview (first 100 chars, cleaned)
  def preview(max_length: 100)
    cleaned = @content.gsub(/[#*{}]/, '').gsub(/\s+/, ' ').strip

    if cleaned.length <= max_length
      cleaned
    else
      truncated = cleaned[0..(max_length - 3)]
      last_period = truncated.rindex('.')
      last_space = truncated.rindex(' ')

      if last_period && last_period > 60
        truncated[0..last_period] + '...'
      elsif last_space && last_space > 60
        truncated[0..last_space] + '...'
      else
        truncated + '...'
      end
    end
  end

  # Convert to hash (public method for API responses)
  def to_h
    super.merge(
      name: @name,
      content: @content,
      preview: preview
    )
  end

  protected

  def load_attributes(attributes)
    @name = attributes[:name] || attributes[:id]
    @content = attributes[:content] || ''
  end

  def self.file_path_for(name)
    File.join(storage_directory, "#{name}.prompt")
  end

  def self.storage_directory
    File.join(File.dirname(__FILE__), '..', 'data', 'prompts')
  end
end

