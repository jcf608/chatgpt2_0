require 'fileutils'
require_relative 'cli_base'
require_relative 'tts_service'

module V2
  # TTS CLI application for converting text to speech
  class TTSCLI < CLIBase
    def initialize
      super
      @voice = "echo"
      @tts_service = TTSService.new(voice: @voice)
    end

    # Setup the CLI application
    def setup
      # Create audio_output directory if it doesn't exist
      FileUtils.mkdir_p('audio_output') unless Dir.exist?('audio_output')

      display_bordered_message("Text-to-Speech CLI v2 - Type 'help' for commands")
      show_main_menu
    end

    # Display the main menu
    def display_menu
      puts "\nMain Menu:"
      puts "1. Process chat file"
      puts "2. Change voice (current: #{@voice})"
      puts "3. Test voice"
      puts "4. Help"
      puts "5. Exit"
    end

    # Process user choice
    def process_choice(choice)
      case choice
      when '1'
        process_chat_file_menu
      when '2'
        interactive_voice_selection
      when '3'
        test_voice
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
        Text-to-Speech CLI Help:

        This tool converts chat files to audio using OpenAI's text-to-speech API.

        Main Menu Options:
        1. Process chat file - Select a chat file to convert to audio
        2. Change voice - Select a different voice for text-to-speech
        3. Test voice - Test the current voice with a sample text
        4. Help - Show this help menu
        5. Exit - Exit the application

        The generated audio files will be saved in the 'audio_output' directory.
      HELP

      puts help_text
    end

    # Show main menu
    def show_main_menu
      puts "\nWelcome to Text-to-Speech CLI v2"
      puts "Current voice: #{@voice}"
      puts "Audio files will be saved to the 'audio_output' directory."
    end

    # Process chat file menu
    def process_chat_file_menu
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

      puts "Select a chat file to convert to audio:"
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

    # Process a chat file and generate audio
    def process_chat_file(file_path)
      puts "Processing chat file: #{File.basename(file_path)}"

      # Ask for output name
      puts "Enter output filename (without extension, leave blank for auto-generated name):"
      print "> "
      output_name = gets.chomp

      # Process the file
      output_file = @tts_service.process_chat_file(file_path, output_name.empty? ? nil : output_name)

      if output_file
        puts "Audio saved to: #{output_file}"

        # Ask if user wants to play the file
        puts "Do you want to play the audio? (y/n)"
        print "> "
        play_choice = gets.chomp.downcase

        if play_choice == 'y' || play_choice == 'yes'
          play_audio_file(output_file)
        end
      else
        puts "Failed to generate audio."
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
      choice = gets.chomp.to_i

      if choice > 0 && choice <= voices.size
        @voice = voices[choice - 1]
        @tts_service = TTSService.new(voice: @voice)
        puts "Voice set to: #{@voice}"
      else
        puts "Invalid selection."
      end
    end

    # Test the current voice
    def test_voice
      puts "Enter text to test the voice (or press Enter for default text):"
      print "> "
      text = gets.chomp

      if text.empty?
        text = "Hello! This is a test of the #{@voice} voice. How does it sound?"
      end

      puts "Testing voice: #{@voice}"
      puts "Text: #{text}"

      @tts_service.speak_text(text)
    end

    private

    # Play an audio file
    def play_audio_file(file)
      case RbConfig::CONFIG['host_os']
      when /darwin/
        system("afplay #{file}")
      when /linux/
        system("aplay #{file}")
      when /mswin|mingw/
        system("start #{file}")
      else
        puts "Audio playback not supported on this platform. File saved to: #{file}"
      end
    end
  end
end
