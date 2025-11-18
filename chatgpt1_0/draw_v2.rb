#!/usr/bin/env ruby

# This is a wrapper script for the v2 implementation of the Draw CLI tool.
# It directly launches the DrawCLI application.

# Add the lib directory to the load path
$LOAD_PATH.unshift(File.expand_path('../v2/lib', __FILE__))

begin
  require 'draw_cli'
  V2::DrawCLI.new.start
rescue LoadError => e
  puts "Error: Failed to load the Draw CLI application: #{e.message}"
  puts "Make sure the v2 implementation is properly installed."
  exit 1
end