#!/usr/bin/env ruby

# minify_files.rb - Utility to minify all files in a folder by removing non-printable characters
# Usage: ruby minify_files.rb <input_folder> [<output_folder>]
# If output_folder is not specified, files will be overwritten in place

require 'fileutils'

class FileMinifier
  attr_reader :input_folder, :output_folder, :overwrite

  def initialize(input_folder, output_folder = nil)
    @input_folder = input_folder
    @output_folder = output_folder
    @overwrite = output_folder.nil?
    
    # Create output directory if specified and doesn't exist
    if !@overwrite && !Dir.exist?(@output_folder)
      FileUtils.mkdir_p(@output_folder)
    end
  end

  def minify_all_files
    # Check if input folder exists
    unless Dir.exist?(@input_folder)
      puts "Error: Input folder '#{@input_folder}' not found."
      return false
    end

    # Get all files in the input folder
    files = Dir.glob(File.join(@input_folder, '*')).select { |f| File.file?(f) }
    
    if files.empty?
      puts "No files found in '#{@input_folder}'."
      return false
    end

    # Process each file
    files.each do |file|
      minify_file(file)
    end

    puts "Successfully minified #{files.length} files."
    true
  end

  private

  def minify_file(file_path)
    begin
      # Read file content
      content = File.read(file_path)
      
      # Remove non-printable characters
      # This keeps only ASCII printable characters (32-126) and newlines
      minified_content = content.gsub(/[^\x20-\x7E\r\n]/, '')
      
      # Determine output path
      output_path = @overwrite ? file_path : File.join(@output_folder, File.basename(file_path))
      
      # Write minified content
      File.write(output_path, minified_content)
      
      puts "Minified: #{file_path} -> #{output_path}"
    rescue => e
      puts "Error processing file '#{file_path}': #{e.message}"
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby minify_files.rb <input_folder> [<output_folder>]"
    puts "If output_folder is not specified, files will be overwritten in place."
    exit 1
  end

  input_folder = ARGV[0]
  output_folder = ARGV[1]

  minifier = FileMinifier.new(input_folder, output_folder)
  success = minifier.minify_all_files
  
  exit(success ? 0 : 1)
end