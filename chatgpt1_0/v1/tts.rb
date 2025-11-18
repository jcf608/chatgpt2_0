#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'fileutils'

class EnhancedTTS
  MAX_RETRIES = 5
  RETRY_DELAY = 2 # seconds

  def initialize(voice: 'echo', api_key: nil)
    @voice = voice
    @api_key = api_key || load_api_key
    @temp_dir = 'temp_segments'
    FileUtils.mkdir_p(@temp_dir)
  end

  def load_api_key
    # Check for API key file first (matching original script)
    if File.exist?('openai_api_key')
      key = File.read('openai_api_key').strip
      return key unless key.empty?
    end

    # Fall back to environment variable
    return ENV['OPENAI_API_KEY'] if ENV['OPENAI_API_KEY']

    # If no key found, prompt for it
    puts "🔑 OpenAI API key not found in 'openai_api_key' file or environment."
    print "Please enter your API key: "
    key = gets.chomp
    return key.empty? ? nil : key
  end

  def process_chat_file(file_path, output_name = nil)
    content = File.read(file_path)
    segments = extract_segments(content)

    output_name ||= File.basename(file_path, '.*')
    puts "🎵 Processing #{segments.length} segments with #{MAX_RETRIES} retries per segment"
    puts "💾 Will save to: #{output_name}.mp3"
    puts "⏸️  Press Ctrl+C to stop"
    puts "-" * 50

    successful_segments = []
    failed_segments = []

    segments.each_with_index do |segment, index|
      segment_num = index + 1
      print "🔊 Processing segment #{segment_num}/#{segments.length}..."

      success = false
      retries = 0

      while retries < MAX_RETRIES && !success
        begin
          audio_data = generate_audio(segment)
          temp_file = File.join(@temp_dir, "segment_#{segment_num.to_s.rjust(3, '0')}.mp3")
          File.binwrite(temp_file, audio_data)
          successful_segments << { file: temp_file, index: segment_num }
          puts " ✅"
          success = true
        rescue => e
          retries += 1
          if retries < MAX_RETRIES
            puts " 🔄 Retry #{retries}/#{MAX_RETRIES}"
            sleep(RETRY_DELAY * retries) # Exponential backoff
          else
            puts " ❌ Failed after #{MAX_RETRIES} attempts: #{e.message}"
            failed_segments << { index: segment_num, error: e.message }
          end
        end
      end
    end

    # Combine successful segments
    if successful_segments.any?
      combine_segments(successful_segments.map { |s| s[:file] }, "#{output_name}.mp3")
      puts "\n✅ Successfully processed #{successful_segments.length}/#{segments.length} segments"
      puts "💾 Saved as: #{output_name}.mp3"
    else
      puts "\n❌ No segments were successfully processed"
    end

    # Report failed segments
    if failed_segments.any?
      puts "\n⚠️  Failed segments:"
      failed_segments.each do |fail|
        puts "   Segment #{fail[:index]}: #{fail[:error]}"
      end
    end

    # Cleanup temp files
    cleanup_temp_files

    puts "\n🎉 Process complete!"
  end

  private

  def extract_segments(content)
    # Extract meaningful segments from chat content
    segments = []

    # Split by user/AI markers and clean up
    parts = content.split(/(?:👤 USER:|🤖 AI:)/)
    parts.each do |part|
      cleaned = part.strip
      next if cleaned.empty?
      next if cleaned.length < 10 # Skip very short segments

      # Remove system prompts and metadata
      next if cleaned.include?('SYSTEM PROMPT:')
      next if cleaned.include?('================')
      next if cleaned.include?('Chat CLI Conversation')

      segments << cleaned
    end

    segments
  end

  def generate_audio(text)
    uri = URI('https://api.openai.com/v1/audio/speech')

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: 'tts-1',
      voice: @voice,
      input: text[0, 4096] # Limit to API max
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                               read_timeout: 60, write_timeout: 60) do |http|
      http.request(request)
    end

    unless response.code == '200'
      raise "API Error: #{response.code} - #{response.body}"
    end

    response.body
  end

  def combine_segments(segment_files, output_file)
    # Create a simple concatenation using system ffmpeg if available
    if system('which ffmpeg > /dev/null 2>&1')
      combine_with_ffmpeg(segment_files, output_file)
    else
      combine_binary(segment_files, output_file)
    end
  end

  def combine_with_ffmpeg(segment_files, output_file)
    list_file = File.join(@temp_dir, 'segments.txt')
    File.open(list_file, 'w') do |f|
      segment_files.each { |file| f.puts "file '#{File.absolute_path(file)}'" }
    end

    system("ffmpeg -f concat -safe 0 -i '#{list_file}' -c copy '#{output_file}' -y > /dev/null 2>&1")
  end

  def combine_binary(segment_files, output_file)
    # Simple binary concatenation (may have slight audio gaps)
    File.open(output_file, 'wb') do |output|
      segment_files.each do |file|
        output.write(File.binread(file))
      end
    end
  end

  def cleanup_temp_files
    FileUtils.rm_rf(@temp_dir) if Dir.exist?(@temp_dir)
  end
end

# File picker functionality
def show_file_picker
  chat_files = Dir.glob('chats/*.txt').select { |f| File.file?(f) }

  # Sort by modification time, newest first
  chat_files.sort_by! { |f| -File.mtime(f).to_f }

  if chat_files.empty?
    puts "❌ No .txt files found in chats/ directory"
    return nil
  end

  puts "🗣️  OpenAI TTS Chat Reader"
  puts "🎤 Voice: echo (David-like)"
  puts "Found #{chat_files.length} chat files"
  puts "=" * 100
  puts
  puts "📚 Available Chat Files:"
  puts "-" * 100

  chat_files.each_with_index do |file, index|
    size = File.size(file) / 1024.0
    mtime = File.mtime(file)
    # Get just the filename without the chats/ prefix
    filename = File.basename(file)
    name_truncated = filename.length > 30 ? "#{filename[0, 27]}..." : filename

    printf "%2d. %-33s %s %5.1fKB",
           index + 1,
           name_truncated,
           mtime.strftime("%m/%d %H:%M"),
           size

    # Two-column layout - print newline only after every second item
    if index.odd?
      puts
    else
      print "  "
    end
  end

  # Add final newline if we ended on an odd-numbered item
  puts if chat_files.length.even?

  puts
  print "🎤 Select a chat to read (1-#{chat_files.length}) or 'q' to quit:\n> "

  choice = gets.chomp.downcase
  return nil if choice == 'q'

  file_index = choice.to_i - 1
  if file_index >= 0 && file_index < chat_files.length
    return chat_files[file_index]
  else
    puts "❌ Invalid selection"
    return nil
  end
end

def show_options_menu(selected_file)
  puts "✨ Selected: #{selected_file[0, 50]}"
  puts
  puts "🎤 Options:"
  puts "  1. Play audio only"
  puts "  2. Save as MP3 file"
  puts "  3. Play and save MP3"
  puts "  q. Quit"
  print "Choose option (1-3 or q): "

  gets.chomp.downcase
end

# CLI interface
if __FILE__ == $0
  # Check if file provided as argument
  if ARGV.length > 0
    chat_file = ARGV[0]
    output_name = ARGV[1]

    unless File.exist?(chat_file)
      puts "❌ File not found: #{chat_file}"
      exit 1
    end

    tts = EnhancedTTS.new
    tts.process_chat_file(chat_file, output_name)
  else
    # Interactive mode
    selected_file = show_file_picker
    exit 0 if selected_file.nil?

    option = show_options_menu(selected_file)
    exit 0 if option == 'q'

    if ['1', '2', '3'].include?(option)
      tts = EnhancedTTS.new
      output_name = File.basename(selected_file, '.*')

      case option
      when '1'
        puts "🎵 Play-only mode not implemented yet - saving to file instead"
        tts.process_chat_file(selected_file, output_name)
      when '2', '3'
        tts.process_chat_file(selected_file, output_name)
      end
    else
      puts "❌ Invalid option"
    end
  end
end