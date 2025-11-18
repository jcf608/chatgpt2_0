#!/usr/bin/env ruby
# migrate_api_keys.rb - Copy API keys from old codebase to new .env file

require 'fileutils'

class ApiKeyMigrator
  # Get the project root (two levels up from script/utilities/)
  # __FILE__ is at script/utilities/migrate_api_keys.rb
  # So ../.. gets us to the project root
  PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  OLD_CODEBASE_PATH = File.join(PROJECT_ROOT, 'chatgpt1_0')
  NEW_ENV_PATH = File.join(PROJECT_ROOT, 'backend', '.env')
  NEW_ENV_EXAMPLE_PATH = File.join(PROJECT_ROOT, 'backend', '.env.example')

  def initialize
    @openai_key = nil
    @venice_key = nil
  end

  def migrate
    puts "🔑 API Key Migration Script"
    puts "=" * 50

    # Check if old codebase exists
    unless Dir.exist?(OLD_CODEBASE_PATH)
      puts "❌ Old codebase not found at: #{OLD_CODEBASE_PATH}"
      return false
    end

    # Load keys from old codebase
    load_openai_key
    load_venice_key

    # Create backend directory if it doesn't exist
    backend_dir = File.dirname(NEW_ENV_PATH)
    FileUtils.mkdir_p(backend_dir) unless Dir.exist?(backend_dir)

    # Create .env file
    create_env_file

    # Create .env.example file
    create_env_example_file

    puts "\n✅ Migration complete!"
    puts "📁 Keys copied to: #{NEW_ENV_PATH}"
    puts "📋 Example file created: #{NEW_ENV_EXAMPLE_PATH}"
    puts "\n⚠️  Remember to add .env to .gitignore!"

    true
  end

  private

  def load_openai_key
    key_file = File.join(OLD_CODEBASE_PATH, 'openAI_api_key')
    
    if File.exist?(key_file)
      @openai_key = File.read(key_file).strip
      puts "✅ Found OpenAI API key"
    else
      # Try environment variable
      @openai_key = ENV['OPENAI_API_KEY']
      if @openai_key
        puts "✅ Found OpenAI API key in environment"
      else
        puts "⚠️  OpenAI API key not found (will be empty in .env)"
      end
    end
  end

  def load_venice_key
    key_file = File.join(OLD_CODEBASE_PATH, 'venice_api_key')
    
    if File.exist?(key_file)
      @venice_key = File.read(key_file).strip
      puts "✅ Found Venice API key"
    else
      # Try environment variable
      @venice_key = ENV['VENICE_API_KEY']
      if @venice_key
        puts "✅ Found Venice API key in environment"
      else
        puts "⚠️  Venice API key not found (will be empty in .env)"
      end
    end
  end

  def create_env_file
    env_content = <<~ENV
      # API Keys
      # These keys are loaded from the old codebase
      # Keep this file secure and never commit it to git!
      
      OPENAI_API_KEY=#{@openai_key || ''}
      VENICE_API_KEY=#{@venice_key || ''}
      
      # Environment
      RACK_ENV=development
      
      # Server Configuration
      PORT=4567
    ENV

    File.write(NEW_ENV_PATH, env_content)
    puts "\n📝 Created .env file"
  end

  def create_env_example_file
    example_content = <<~EXAMPLE
      # API Keys
      # Copy this file to .env and fill in your actual API keys
      
      OPENAI_API_KEY=your_openai_api_key_here
      VENICE_API_KEY=your_venice_api_key_here
      
      # Environment
      RACK_ENV=development
      
      # Server Configuration
      PORT=4567
    EXAMPLE

    File.write(NEW_ENV_EXAMPLE_PATH, example_content)
    puts "📋 Created .env.example file"
  end
end

# Run migration if executed directly
if __FILE__ == $0
  migrator = ApiKeyMigrator.new
  success = migrator.migrate
  exit(success ? 0 : 1)
end

