#!/usr/bin/env ruby

# chat_to_md.rb - Utility to convert chat/*.txt files to Markdown format
# Usage: ruby chat_to_md.rb <input_file> [<output_file>]
# If output_file is not specified, it will be created with the same name as input_file but with .md extension

require 'fileutils'

class ChatToMarkdown
  attr_reader :input_file, :output_file

  def initialize(input_file, output_file = nil)
    @input_file = input_file
    @output_file = output_file || input_file.sub(/\.txt$/, '.md')
  end

  def convert
    content = File.read(input_file)
    format = detect_format(content)
    markdown = convert_to_markdown(content, format)

    # Create output directory if it doesn't exist
    output_dir = File.dirname(output_file)
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

    File.write(output_file, markdown)
    puts "Converted #{input_file} to #{output_file}"
  end

  private

  def detect_format(content)
    if content.match?(/^🤖 System:/)
      :emoji_format
    elsif content.match?(/^Chat CLI Conversation/)
      :cli_header_format
    elsif content.match?(/^>/)
      :cli_format
    else
      :unknown_format
    end
  end

  def convert_to_markdown(content, format)
    case format
    when :emoji_format
      convert_emoji_format(content)
    when :cli_header_format
      convert_cli_header_format(content)
    when :cli_format
      convert_cli_format(content)
    else
      convert_unknown_format(content)
    end
  end

  def convert_emoji_format(content)
    # Format with emoji prefixes for system, user, and assistant messages
    markdown = "# Chat Conversation\n\n"

    # Extract and format system message if present
    if content.match(/^🤖 System: (.+?)(?=\n\n👤 User:|\z)/m)
      system_content = $1.strip
      markdown += "## System\n\n```json\n#{system_content}\n```\n\n"
    end

    # Extract conversation
    conversation = content.gsub(/^🤖 System: .+?(?=\n\n👤 User:|\z)/m, '')

    # Convert user and assistant messages
    conversation.split(/(?=^👤 User:|^🤖 Assistant:)/m).each do |message|
      if message.start_with?('👤 User:')
        user_content = message.sub(/^👤 User:/, '').strip
        markdown += "## User\n\n#{user_content}\n\n"
      elsif message.start_with?('🤖 Assistant:')
        assistant_content = message.sub(/^🤖 Assistant:/, '').strip
        markdown += "## Assistant\n\n#{assistant_content}\n\n"
      end
    end

    markdown
  end

  def convert_cli_header_format(content)
    # Format with metadata header and emoji prefixes for user and AI messages
    markdown = "# Chat Conversation\n\n"

    # Extract metadata
    if content.match(/^Chat CLI Conversation\n==+\n(.+?)\n==+/m)
      metadata = $1.strip
      markdown += "## Metadata\n\n```\n#{metadata}\n```\n\n"
    end

    # Extract system prompt if present
    if content.match(/^🎭 SYSTEM PROMPT:\n(.+?)(?=\n\n👤 USER:|\z)/m)
      system_content = $1.strip
      markdown += "## System\n\n```\n#{system_content}\n```\n\n"
    end

    # Convert user and AI messages
    content.split(/(?=^👤 USER:|^🤖 AI:)/m).each do |message|
      if message.start_with?('👤 USER:')
        user_content = message.sub(/^👤 USER:/, '').strip
        markdown += "## User\n\n#{user_content}\n\n"
      elsif message.start_with?('🤖 AI:')
        ai_content = message.sub(/^🤖 AI:/, '').strip
        markdown += "## Assistant\n\n#{ai_content}\n\n"
      end
    end

    markdown
  end

  def convert_cli_format(content)
    # Command-line interface format with "> " for user inputs
    markdown = "# Chat Conversation\n\n"

    # Extract CLI header if present
    if content.match(/^(.+?)(?=\n\n>|\z)/m)
      header = $1.strip
      markdown += "## CLI Info\n\n```\n#{header}\n```\n\n"
    end

    # Split content into user inputs and ChatGPT responses
    in_user_input = false
    user_input = ""
    chatgpt_response = ""

    content.each_line do |line|
      if line.start_with?("> ")
        # If we were collecting a ChatGPT response, add it to markdown
        if !chatgpt_response.empty?
          markdown += "## Assistant\n\n#{chatgpt_response.strip}\n\n"
          chatgpt_response = ""
        end

        # Start or continue collecting user input
        in_user_input = true
        user_input += line.sub(/^> /, '')
      elsif line.strip.empty? && in_user_input
        # Empty line after user input means end of user input
        markdown += "## User\n\n#{user_input.strip}\n\n"
        user_input = ""
        in_user_input = false
      elsif in_user_input
        # Continue collecting user input (multi-line)
        user_input += line
      else
        # Collecting ChatGPT response
        chatgpt_response += line
      end
    end

    # Add any remaining user input or ChatGPT response
    if !user_input.empty?
      markdown += "## User\n\n#{user_input.strip}\n\n"
    end
    if !chatgpt_response.empty?
      markdown += "## Assistant\n\n#{chatgpt_response.strip}\n\n"
    end

    markdown
  end

  def convert_unknown_format(content)
    # For unknown formats, just wrap the content in markdown
    "# Chat Conversation\n\n```\n#{content}\n```\n"
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby chat_to_md.rb <input_file> [<output_file>]"
    exit 1
  end

  input_file = ARGV[0]
  output_file = ARGV[1]

  unless File.exist?(input_file)
    puts "Error: Input file '#{input_file}' not found."
    exit 1
  end

  converter = ChatToMarkdown.new(input_file, output_file)
  converter.convert
end
