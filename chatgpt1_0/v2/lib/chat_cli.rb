require 'fileutils'
require_relative 'cli_base'
require_relative 'openai_client'
require_relative 'venice_client'
require_relative 'tts_service'

module V2
  # Chat CLI application
  class ChatCLI < CLIBase
    OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
    VENICE_API_URL = "https://api.venice.ai/api/v1/chat/completions"
    TEXT_WRAP_WIDTH = 50  # Width for word wrapping

    def initialize
      super
      @api_provider = 'venice'  # Changed default from 'openai' to 'venice'
      @conversation = []
      @system_prompt = nil
      @base_system_prompt = nil  # Store the base system prompt separately
      @tts_enabled = false
      @voice = "echo"
    end

    # Setup the CLI application
    def setup
      # Load API keys
      @openai_client = OpenAIClient.new
      @venice_client = VeniceClient.new

      # Create TTS service
      @tts_service = TTSService.new(voice: @voice)

      # Create chats directory if it doesn't exist
      FileUtils.mkdir_p('chats') unless Dir.exist?('chats')

      # Load base system prompt from system_prompts.txt
      load_base_system_prompt

      # Parse command line arguments
      parse_arguments

      # If no specific prompt was selected via arguments, just use the base
      finalize_system_prompt if @system_prompt.nil?

      display_bordered_message("ChatGPT CLI v2 - Type 'help' for commands")
    end

    # Load the base system prompt that's always included
    def load_base_system_prompt
      system_prompts_file = File.join(File.dirname(__FILE__), 'system_prompts.txt')
      
      if File.exist?(system_prompts_file)
        @base_system_prompt = File.read(system_prompts_file).strip
        puts "✅ Loaded base system prompts from #{system_prompts_file}"
      else
        puts "⚠️  Warning: #{system_prompts_file} not found. Using minimal base prompt."
        @base_system_prompt = "You are a helpful assistant."
      end
    end

    # Parse command line arguments
    def parse_arguments
      ARGV.each_with_index do |arg, index|
        case arg
        when '-p', '--prompt'
          prompt_name = ARGV[index + 1]
          load_prompt_by_name(prompt_name) if prompt_name
        when '-v', '--voice'
          @voice = ARGV[index + 1] if ARGV[index + 1]
          @tts_service = TTSService.new(voice: @voice)
        when '-t', '--tts'
          @tts_enabled = true
        when '--venice'
          @api_provider = 'venice'
        when '--openai'
          @api_provider = 'openai'
        end
      end
    end

    # Display the main menu
    def display_menu
      # In chat mode, we don't display a menu, just wait for user input
    end

    # Process user choice
    def process_choice(choice)
      case choice.downcase
      when 'exit', 'quit'
        offer_save_on_exit if has_conversation_content?
        exit_app
      when 'help'
        show_help_menu
      when 'clear'
        @conversation = []
        # Re-add the system prompt after clearing
        finalize_system_prompt
        puts "Conversation cleared."
      when 'save'
        save_chat_dialog
      when 'tts on'
        @tts_enabled = true
        puts "Text-to-speech enabled."
      when 'tts off'
        @tts_enabled = false
        puts "Text-to-speech disabled."
      when 'voice'
        interactive_voice_selection
      when 'prompt'
        interactive_prompt_selection
      when 'provider'
        show_provider_menu
      when 'status'
        show_status
      else
        send_message(choice)
      end
    end

    # Show help menu
    def show_help_menu
      help_text = <<~HELP
        Available commands:
          help       - Show this help menu
          exit, quit - Return to main program
          clear      - Clear the current conversation
          save       - Save the conversation to a file
          tts on     - Enable text-to-speech
          tts off    - Disable text-to-speech
          voice      - Select a voice for text-to-speech
          prompt     - Select a system prompt
          provider   - Switch between API providers (OpenAI/Venice)
          status     - Show current settings

        Any other input will be sent as a message to the AI.
      HELP

      puts wrap_text(help_text)
    end

    # Show current status
    def show_status
      status_text = <<~STATUS
        Current settings:
          API Provider: #{@api_provider}
          TTS Enabled: #{@tts_enabled}
          Voice: #{@voice}
          System Prompt: #{@system_prompt ? @system_prompt[:name] : 'base only'}
      STATUS

      puts wrap_text(status_text)
    end

    # Show provider menu
    def show_provider_menu
      puts "Select API provider:"
      puts "1. OpenAI"
      puts "2. Venice"

      print "> "
      begin
        choice = gets.chomp.to_i

        case choice
        when 1
          @api_provider = 'openai'
          puts "Switched to OpenAI provider."
        when 2
          @api_provider = 'venice'
          puts "Switched to Venice provider."
        else
          puts "Invalid selection."
        end
      rescue Errno::EIO, IOError => e
        puts "\nI/O error occurred. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      rescue Interrupt
        puts "\nOperation interrupted. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      end
    end

    # Load a prompt by name
    def load_prompt_by_name(prompt_name)
      prompt_path = File.join('prompts', "#{prompt_name}.prompt")

      if File.exist?(prompt_path)
        content = File.read(prompt_path)
        @system_prompt = {
          name: prompt_name,
          content: content
        }
        finalize_system_prompt
        puts "✅ Loaded prompt: #{prompt_name} (added to base system prompt)"
      else
        puts "❌ Prompt not found: #{prompt_name}"
        puts "📁 Available prompts in ./prompts directory:"
        Dir.glob(File.join('prompts', '*.prompt')).each do |file|
          puts "   - #{File.basename(file, '.prompt')}"
        end
      end
    end

    # Finalize the system prompt by combining base + user selection
    def finalize_system_prompt
      # Start with the base system prompt
      combined_content = @base_system_prompt.dup

      # Add user-selected prompt if any
      if @system_prompt && @system_prompt[:content]
        combined_content = [combined_content, @system_prompt[:content]].join("\n\n")
      end

      # Update the conversation with the combined prompt
      @conversation = @conversation.select { |msg| msg["role"] != "system" }
      @conversation.unshift({ "role" => "system", "content" => combined_content })

      puts "🎭 System prompt ready: base + #{@system_prompt ? @system_prompt[:name] : 'no additional prompt'}"
    end

    # Interactive prompt selection
    def interactive_prompt_selection
      prompt_files = Dir.glob(File.join('prompts', "*.prompt")).map { |f| File.basename(f, '.prompt') }

      if prompt_files.empty?
        puts "No prompt files found in the 'prompts' directory."
        return
      end

      puts "Select a prompt (will be added to base system prompt):"
      prompt_files.each_with_index do |prompt, index|
        puts "#{index + 1}. #{prompt}"
      end

      print "> "
      begin
        choice = gets.chomp.to_i

        if choice > 0 && choice <= prompt_files.size
          load_prompt_by_name(prompt_files[choice - 1])
        else
          puts "Invalid selection."
        end
      rescue Errno::EIO, IOError => e
        puts "\nI/O error occurred. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      rescue Interrupt
        puts "\nOperation interrupted. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      end
    end

    # Interactive voice selection
    def interactive_voice_selection
      voices = TTSService::AVAILABLE_VOICES

      puts "Select a voice:"
      voices.each_with_index do |voice, index|
        puts "#{index + 1}. #{voice}"
      end

      print "> "
      begin
        choice = gets.chomp.to_i

        if choice > 0 && choice <= voices.size
          @voice = voices[choice - 1]
          @tts_service = TTSService.new(voice: @voice)
          puts "Voice set to: #{@voice}"
        else
          puts "Invalid selection."
        end
      rescue Errno::EIO, IOError => e
        puts "\nI/O error occurred. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      rescue Interrupt
        puts "\nOperation interrupted. Returning to main menu."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
      end
    end

    # Send a message to the AI
    def send_message(message)
      # Add the user message to the conversation
      @conversation << { "role" => "user", "content" => message }

      # Make the API request
      response = make_api_request

      if response && response['choices'] && response['choices'][0] && response['choices'][0]['message']
        # Extract the assistant's response
        assistant_message = response['choices'][0]['message']['content']

        # Add the assistant's response to the conversation
        @conversation << { "role" => "assistant", "content" => assistant_message }

        # Check if message starts with "Developer Mode enabled"
        if assistant_message.strip.downcase.start_with?("developer mode enabled")
          # Extract any text after "Developer Mode enabled."
          remaining_text = assistant_message.strip
          
          # Try to find where the actual content starts (after the first sentence)
          if remaining_text.include?(".")
            parts = remaining_text.split(".", 2)
            if parts.length > 1 && !parts[1].strip.empty?
              # Display only the content after "Developer Mode enabled."
              puts "\n🤖 Assistant:"
              puts wrap_text(parts[1].strip)
              
              # Speak the remaining text if TTS is enabled
              if @tts_enabled
                @tts_service.speak_text(parts[1].strip)
              end
              return
            end
          end
          
          # If it's just "Developer Mode enabled" with nothing else, suppress entirely
          return
        end

        # Display the response normally
        puts "\n🤖 Assistant:"
        puts wrap_text(assistant_message)

        # Speak the response if TTS is enabled
        if @tts_enabled
          @tts_service.speak_text(assistant_message)
        end
      else
        puts "Error: Failed to get a response from the API."
        if response && response['error']
          error_message = response['error']['message'] || "Unknown error"
          puts "API Error: #{error_message}"
        end
      end
    end

    # Make an API request
    def make_api_request
      case @api_provider
      when 'openai'
        @openai_client.chat_completion(@conversation)
      when 'venice'
        @venice_client.chat_completion(@conversation)
      else
        puts "Unknown provider: #{@api_provider}, defaulting to OpenAI"
        @openai_client.chat_completion(@conversation)
      end
    end

    # Save the chat dialog to a file
    def save_chat_dialog
      # Create a filename based on the first user message
      first_user_message = @conversation.find { |msg| msg["role"] == "user" }

      if first_user_message.nil?
        puts "No conversation to save."
        return
      end

      # Create a filename from the first few words of the first message
      message_start = first_user_message["content"][0..30].strip.gsub(/[^0-9A-Za-z\s]/, '')
      filename = message_start.gsub(/\s+/, '_')

      # Add timestamp
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      filepath = File.join('chats', "#{timestamp}_#{filename}.txt")

      # Save the conversation
      save_text_file(filepath)
    end

    # Save the conversation to a text file
    def save_text_file(filepath)
      File.open(filepath, 'w') do |file|
        # Write the conversation first
        @conversation.each do |message|
          case message["role"]
          when "user"
            file.puts "👤 User: #{message["content"]}"
          when "assistant"
            file.puts "🤖 Assistant: #{message["content"]}"
          end
          file.puts unless message["role"] == "system"
        end

        # Write system prompt configuration after the conversation
        file.puts "\n" + "="*50 + "\n"
        file.puts "🤖 System Prompt Configuration:"
        file.puts "   Base: system_prompts.txt"
        if @system_prompt
          file.puts "   Additional: #{@system_prompt[:name]}"
        end
        file.puts "\n" + "="*50

        # Generate and add prompt summary
        puts "\n🤔 Generating system prompt summary..."
        prompt_summary = generate_prompt_summary
        
        if prompt_summary
          file.puts "\n🎭 AI-Generated Prompt Summary:"
          file.puts "-"*50
          file.puts wrap_text(prompt_summary)
          file.puts "\n" + "="*50
          file.puts "\nGenerated on: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        end

        # Now add the full system prompt at the very bottom
        file.puts "\n\n" + "="*50
        file.puts "\n📝 Full System Prompt:"
        file.puts "-"*50
        system_msg = @conversation.find { |msg| msg["role"] == "system" }
        if system_msg
          file.puts system_msg["content"]
        end
        file.puts "\n" + "="*50
      end

      puts "Conversation saved to: #{filepath}"
      filepath
    end

    # Generate a summary of the system prompts using the AI
    def generate_prompt_summary
      # Get the system prompt content
      system_msg = @conversation.find { |msg| msg["role"] == "system" }
      return nil unless system_msg
      
      # Create a simple conversation just for summarizing the prompt
      summary_conversation = [
        { "role" => "user", "content" => <<~PROMPT
          Please provide a brief, clear summary of what the following system prompt instructs you to do. 
          Describe the key behaviors, personality traits, and any special modes or capabilities it enables.
          Keep it concise (2-3 sentences max).
          
          System prompt to summarize:
          #{system_msg["content"]}
        PROMPT
        }
      ]

      # Make API request for summary
      response = case @api_provider
                 when 'openai'
                   @openai_client.chat_completion(summary_conversation)
                 when 'venice'
                   @venice_client.chat_completion(summary_conversation)
                 end

      if response && response['choices'] && response['choices'][0] && response['choices'][0]['message']
        summary = response['choices'][0]['message']['content']
        puts "✅ Prompt summary generated successfully"
        return summary
      else
        puts "⚠️  Could not generate prompt summary - API error"
        return nil
      end
    rescue => e
      puts "⚠️  Could not generate prompt summary - #{e.message}"
      return nil
    end

    # Helper method to wrap text to a specified width
    def wrap_text(text, width = TEXT_WRAP_WIDTH)
      return text if text.nil?

      lines = []
      text.each_line do |line|
        # If the line is shorter than the width, keep it as is
        if line.length <= width
          lines << line
        else
          # Split the line into words
          words = line.split(/\s+/)
          current_line = ""

          words.each do |word|
            # If adding the word would exceed the width, start a new line
            if current_line.length + word.length + 1 > width && !current_line.empty?
              lines << current_line
              current_line = word
            else
              # Add the word to the current line with a space if not the first word
              current_line = current_line.empty? ? word : "#{current_line} #{word}"
            end
          end

          # Add the last line if not empty
          lines << current_line unless current_line.empty?
        end
      end

      lines.join("\n")
    end

    # Check if conversation has meaningful content (not just system prompts)
    def has_conversation_content?
      @conversation.any? { |msg| msg["role"] == "user" || msg["role"] == "assistant" }
    end

    # Offer to save conversation before exiting
    def offer_save_on_exit
      puts "\n💾 Would you like to save this conversation before exiting? (y/n)"
      print "Save? > "
      
      response = gets.chomp.downcase
      
      if response == 'y' || response == 'yes'
        save_chat_dialog
        puts "✅ Conversation saved!"
      elsif response == 'n' || response == 'no'
        puts "📄 Conversation not saved."
      else
        puts "🤷 I'll take that as a no. Conversation not saved."
      end
    end
  end
end