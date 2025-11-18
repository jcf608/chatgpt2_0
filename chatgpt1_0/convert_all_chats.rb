#!/usr/bin/env ruby

# convert_all_chats.rb - Utility to convert all chat/*.txt files to Markdown format
# Usage: ruby convert_all_chats.rb [<output_dir>]
# If output_dir is not specified, the output files will be created in the 'chats/markdown' directory

require_relative 'chat_to_md.rb'
require 'fileutils'

# Get output directory from command line arguments or use default
output_dir = ARGV[0] || 'chats/markdown'

# Find all .txt files in the chats directory
chat_files = Dir.glob('chats/*.txt')

if chat_files.empty?
  puts "No chat files found in the chats directory."
  exit 0
end

# Convert each chat file to Markdown
puts "Converting #{chat_files.size} chat files to Markdown..."

chat_files.each do |chat_file|
  # Determine output file path
  # Create output directory if it doesn't exist
  FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

  # Use the same filename but with .md extension in the output directory
  output_file = File.join(output_dir, File.basename(chat_file, '.txt') + '.md')

  # Convert the file
  begin
    converter = ChatToMarkdown.new(chat_file, output_file)
    converter.convert
  rescue => e
    puts "Error converting #{chat_file}: #{e.message}"
  end
end

puts "Conversion complete!"
