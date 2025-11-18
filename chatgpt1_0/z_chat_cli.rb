#!/usr/bin/env ruby

# This is a wrapper script for the v2 implementation of the ChatGPT CLI tools.
# It simply forwards all arguments to the v2/bin/cli.rb script.

script_path = File.expand_path('../v2/bin/cli.rb', __FILE__)

if File.exist?(script_path)
  # Use system with ruby to ensure path with spaces is handled correctly
  begin
    system("ruby", script_path, *ARGV)
    exit $?.exitstatus
  rescue Interrupt
    # Handle CTRL+C gracefully
    puts "\nExiting application..."
    exit 130  # Standard exit code for interrupt
  end
else
  puts "Error: v2 implementation not found at #{script_path}"
  exit 1
end
