require 'io/console'

module V2
  # Base class for CLI applications
  class CLIBase
    def initialize
      @running = true
    end

    # Start the CLI application
    def start
      setup

      while @running
        display_menu
        choice = get_user_choice
        process_choice(choice)
      end

      cleanup
    end

    # Setup the CLI application
    def setup
      # To be implemented by subclasses
    end

    # Display the main menu
    def display_menu
      # To be implemented by subclasses
    end

    # Get user choice from input
    def get_user_choice
      print "> "
      begin
        gets.chomp
      rescue Errno::EIO, IOError => e
        # Handle I/O errors that might occur after an interrupt
        puts "\nI/O error occurred. Restarting input..."
        # Reset standard input
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
        retry
      rescue Interrupt
        # Handle CTRL+C gracefully
        puts "\nOperation interrupted. Press Enter to continue..."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
        ""
      end
    end

    # Process user choice
    def process_choice(choice)
      # To be implemented by subclasses
    end

    # Clean up resources
    def cleanup
      # To be implemented by subclasses
    end

    # Exit the application
    def exit_app
      @running = false
    end

    # Display a message with a border
    def display_bordered_message(message, border_char = "=")
      width = [80, terminal_width].min
      border = border_char * width

      puts border
      puts message
      puts border
    end

    # Get terminal width
    def terminal_width
      IO.console.winsize[1] rescue 80
    end

    # Wrap text to fit terminal width
    def wrap_text(text, width = nil)
      width ||= terminal_width
      text.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
    end

    # Show help menu
    def show_help_menu
      # To be implemented by subclasses
    end

    # List files in a directory with a numbered menu
    def list_files_menu(directory, extension = nil)
      files = Dir.glob(File.join(directory, extension || "*")).sort_by { |f| File.mtime(f) }.reverse

      if files.empty?
        puts "No files found in #{directory}"
        return nil
      end

      puts "Select a file:"
      files.each_with_index do |file, index|
        filename = File.basename(file)
        puts "#{index + 1}. #{filename}"
      end

      print "> "
      begin
        choice = gets.chomp.to_i

        if choice > 0 && choice <= files.size
          files[choice - 1]
        else
          puts "Invalid selection"
          nil
        end
      rescue Errno::EIO, IOError => e
        # Handle I/O errors that might occur after an interrupt
        puts "\nI/O error occurred. Restarting input..."
        # Reset standard input
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
        retry
      rescue Interrupt
        # Handle CTRL+C gracefully
        puts "\nOperation interrupted. Returning to main menu..."
        STDIN.reopen('/dev/tty') if STDIN.closed? || STDIN.eof?
        nil
      end
    end
  end
end
