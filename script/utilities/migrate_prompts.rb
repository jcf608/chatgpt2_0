#!/usr/bin/env ruby

# Migrate prompts from chatgpt1_0 to new codebase
# Copies all .prompt files to backend/data/prompts/

require 'fileutils'

OLD_PROMPTS_DIR = File.join(File.dirname(__FILE__), '..', '..', 'chatgpt1_0', 'prompts')
NEW_PROMPTS_DIR = File.join(File.dirname(__FILE__), '..', '..', 'backend', 'data', 'prompts')

def find_prompt_files(directory)
  files = []
  Dir.glob(File.join(directory, '**', '*.prompt')).each do |file|
    # Skip files with "copy" in the name
    next if file.include?(' copy.')
    files << file
  end
  files
end

def sanitize_filename(filename)
  # Remove path and extension, keep just the name
  name = File.basename(filename, '.prompt')
  # Replace spaces and special chars with underscores
  name.gsub(/[^a-zA-Z0-9_-]/, '_')
end

def migrate_prompts
  unless Dir.exist?(OLD_PROMPTS_DIR)
    puts "Error: Old prompts directory not found: #{OLD_PROMPTS_DIR}"
    exit 1
  end

  # Ensure new directory exists
  FileUtils.mkdir_p(NEW_PROMPTS_DIR)

  # Find all prompt files
  prompt_files = find_prompt_files(OLD_PROMPTS_DIR)
  
  if prompt_files.empty?
    puts "No prompt files found in #{OLD_PROMPTS_DIR}"
    exit 0
  end

  puts "Found #{prompt_files.length} prompt files to migrate..."
  puts

  copied = 0
  skipped = 0
  errors = 0

  prompt_files.each do |old_file|
    begin
      # Read content
      content = File.read(old_file)
      
      # Generate new filename
      old_name = File.basename(old_file, '.prompt')
      new_name = sanitize_filename(old_name)
      new_file = File.join(NEW_PROMPTS_DIR, "#{new_name}.prompt")
      
      # Skip if already exists
      if File.exist?(new_file)
        puts "  ⏭  Skipped: #{new_name} (already exists)"
        skipped += 1
        next
      end
      
      # Copy file
      File.write(new_file, content)
      puts "  ✓  Copied: #{old_name} → #{new_name}"
      copied += 1
    rescue StandardError => e
      puts "  ✗  Error copying #{File.basename(old_file)}: #{e.message}"
      errors += 1
    end
  end

  puts
  puts "Migration complete!"
  puts "  Copied: #{copied}"
  puts "  Skipped: #{skipped}"
  puts "  Errors: #{errors}"
  puts
  puts "Prompts are now in: #{NEW_PROMPTS_DIR}"
end

if __FILE__ == $0
  migrate_prompts
end

