#!/usr/bin/env ruby

require 'fileutils'

# Define source and target directories
source_dir = 'chats'
target_dir = 'chats/no_cr_lf'

# Create target directory if it doesn't exist
FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

# Find all .txt files in the source directory
txt_files = Dir.glob(File.join(source_dir, '*.txt'))

# Process each file
txt_files.each do |file_path|
  # Skip files in subdirectories like 'chats/markdown'
  next if file_path.include?('/markdown/') || file_path.include?('/no_cr_lf/')
  
  # Get the base filename
  filename = File.basename(file_path)
  
  # Read the file content
  content = File.read(file_path)
  
  # Remove CR LF characters (Windows line endings)
  # This replaces \r\n with \n
  modified_content = content.gsub("\r\n", "\n")
  
  # Also remove any standalone \r characters
  modified_content = modified_content.gsub("\r", "")
  
  # Create the output file path
  output_path = File.join(target_dir, filename)
  
  # Write the modified content to the output file
  File.write(output_path, modified_content)
  
  puts "Processed: #{filename}"
end

puts "All files processed. Modified versions saved to #{target_dir}/"