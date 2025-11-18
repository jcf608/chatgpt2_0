require 'fileutils'
require_relative 'cli_base'
require_relative 'image_generator'

module V2
  # Draw CLI application for generating images from chat content
  class DrawCLI < CLIBase
    def initialize
      super
      @provider = 'openai'
      @image_generator = ImageGenerator.new(provider: @provider)
    end
    
    # Setup the CLI application
    def setup
      # Create illustrations directory if it doesn't exist
      FileUtils.mkdir_p('illustrations') unless Dir.exist?('illustrations')
      
      display_bordered_message("Chat to Image Generator v2 - Type 'help' for commands")
      show_main_menu
    end
    
    # Display the main menu
    def display_menu
      puts "\nMain Menu:"
      puts "1. Generate images from chat file"
      puts "2. Import prompts from file"
      puts "3. Switch provider (current: #{@provider})"
      puts "4. Help"
      puts "5. Exit"
    end
    
    # Process user choice
    def process_choice(choice)
      case choice
      when '1'
        process_chat_selection
      when '2'
        import_prompts_menu
      when '3'
        toggle_provider_menu
      when '4'
        show_help_menu
      when '5', 'exit', 'quit'
        exit_app
      else
        puts "Invalid choice. Please try again."
      end
    end
    
    # Show help menu
    def show_help_menu
      help_text = <<~HELP
        Chat to Image Generator Help:
        
        This tool generates images based on the content of chat files.
        
        Main Menu Options:
        1. Generate images from chat file - Select a chat file to generate images from
        2. Import prompts from file - Import image prompts from a file
        3. Switch provider - Toggle between OpenAI and Venice image generation
        4. Help - Show this help menu
        5. Exit - Exit the application
        
        The generated images will be saved in the 'illustrations' directory.
      HELP
      
      puts help_text
    end
    
    # Show main menu
    def show_main_menu
      puts "\nWelcome to Chat to Image Generator v2"
      puts "Provider: #{get_provider_emoji} #{@provider.capitalize}"
      puts "Images will be saved to the 'illustrations' directory."
    end
    
    # Get provider emoji
    def get_provider_emoji
      case @provider
      when 'openai'
        "🤖"
      when 'venice'
        "🎭"
      else
        "📷"
      end
    end
    
    # Toggle provider menu
    def toggle_provider_menu
      puts "Select image generation provider:"
      puts "1. OpenAI (DALL-E)"
      puts "2. Venice"
      
      print "> "
      choice = gets.chomp
      
      case choice
      when '1'
        toggle_provider('openai')
      when '2'
        toggle_provider('venice')
      else
        puts "Invalid choice. Provider not changed."
      end
    end
    
    # Toggle the active provider
    def toggle_provider(provider)
      if @image_generator.toggle_provider(provider)
        @provider = provider
        puts "Provider switched to: #{get_provider_emoji} #{@provider.capitalize}"
      end
    end
    
    # Process chat selection
    def process_chat_selection
      # Check if chats directory exists
      unless Dir.exist?('chats')
        puts "Error: 'chats' directory not found."
        return
      end
      
      # Get list of chat files
      chat_files = Dir.glob(File.join('chats', "*.txt")).sort_by { |f| File.mtime(f) }.reverse
      
      if chat_files.empty?
        puts "No chat files found in the 'chats' directory."
        return
      end
      
      puts "Select a chat file to generate images from:"
      chat_files.each_with_index do |file, index|
        filename = File.basename(file)
        preview = get_file_preview(file)
        puts "#{index + 1}. #{filename} - #{preview}"
      end
      
      print "> "
      choice = gets.chomp.to_i
      
      if choice > 0 && choice <= chat_files.size
        selected_file = chat_files[choice - 1]
        process_chat_file(selected_file)
      else
        puts "Invalid selection."
      end
    end
    
    # Get a preview of the file content
    def get_file_preview(filename)
      content = File.read(filename)
      
      # Find the first user message
      user_message = content.match(/👤 User: (.+)/)
      
      if user_message
        # Truncate the message if it's too long
        message = user_message[1].strip
        if message.length > 50
          message = message[0..47] + "..."
        end
        message
      else
        "No user message found"
      end
    end
    
    # Process a chat file and generate images
    def process_chat_file(file_path)
      puts "Processing chat file: #{File.basename(file_path)}"
      
      # Generate images
      image_paths = @image_generator.process_chat_file(file_path)
      
      if image_paths.empty?
        puts "No images were generated."
      else
        puts "\nGenerated #{image_paths.size} images:"
        image_paths.each do |path|
          puts "- #{path}"
        end
      end
    end
    
    # Import prompts menu
    def import_prompts_menu
      puts "Select a prompt file to import:"
      
      # Check if prompts directory exists
      unless Dir.exist?('prompts')
        puts "Error: 'prompts' directory not found."
        return
      end
      
      # Get list of prompt files
      prompt_files = Dir.glob(File.join('prompts', "*.prompt")).sort_by { |f| File.mtime(f) }.reverse
      
      if prompt_files.empty?
        puts "No prompt files found in the 'prompts' directory."
        return
      end
      
      prompt_files.each_with_index do |file, index|
        filename = File.basename(file)
        puts "#{index + 1}. #{filename}"
      end
      
      print "> "
      choice = gets.chomp.to_i
      
      if choice > 0 && choice <= prompt_files.size
        selected_file = prompt_files[choice - 1]
        import_and_generate(selected_file)
      else
        puts "Invalid selection."
      end
    end
    
    # Import prompts from a file and generate images
    def import_and_generate(prompt_file)
      puts "Importing prompts from: #{File.basename(prompt_file)}"
      
      content = File.read(prompt_file)
      prompts = parse_prompt_file(content)
      
      if prompts.empty?
        puts "No valid prompts found in the file."
        return
      end
      
      puts "Found #{prompts.size} prompts:"
      prompts.each_with_index do |prompt, index|
        puts "#{index + 1}. #{prompt[:title]}"
      end
      
      puts "\nGenerating images..."
      
      # Generate images for each prompt
      images = []
      chat_name = File.basename(prompt_file, '.prompt')
      
      prompts.each_with_index do |prompt, index|
        image_path = @image_generator.generate_image(prompt, chat_name, index + 1)
        images << image_path if image_path
      end
      
      if images.empty?
        puts "No images were generated."
      else
        puts "\nGenerated #{images.size} images:"
        images.each do |path|
          puts "- #{path}"
        end
      end
    end
    
    # Parse a prompt file to extract prompts
    def parse_prompt_file(content)
      prompts = []
      
      # Try to parse as a structured prompt file
      sections = content.split(/\n\s*\n/)
      
      sections.each do |section|
        # Look for title and description
        if section =~ /^(.+?):\s*(.+)/m
          title = $1.strip
          description = $2.strip
          
          prompts << {
            title: title,
            description: description,
            chat_name: "imported"
          }
        end
      end
      
      prompts
    end
  end
end