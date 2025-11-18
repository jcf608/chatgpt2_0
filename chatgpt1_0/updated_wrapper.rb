#!/usr/bin/env ruby

# This is a wrapper script for the v2 implementation of the ChatGPT CLI tools.
# It simply forwards all arguments to the v2/bin/cli.rb script.

script_path = File.expand_path('../chat_cli.rb', __FILE__)

if File.exist?(script_path)
  # Use system with ruby to ensure path with spaces is handled correctly
  begin
    result = system("ruby", script_path, *ARGV)
    exit_code = $?.exitstatus
    
    # Adjust exit code based on nesting level if needed
    # You can customize this logic based on your specific requirements
    if exit_code == 5
      exit 4  # Convert exit 5 to exit 4 for nested scenarios
    else
      exit exit_code
    end
    
  rescue Interrupt
    # Handle CTRL+C gracefully
    puts "\nExiting application..."
    exit 130  # Standard exit code for interrupt
  rescue => e
    puts "Error running script: #{e.message}"
    exit 1
  end
else
  puts "Error: chat_cli.rb not found at #{script_path}"
  exit 1
end