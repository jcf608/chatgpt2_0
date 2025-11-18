require_relative 'base_service'
require_relative '../lib/api_clients/openai_client'
require 'fileutils'

# TTSService - Text-to-speech service
# ALWAYS uses OpenAI (regardless of chat provider)
# Handles intelligent text chunking and audio segment combination

class TTSService < BaseService
  MAX_CHUNK_LENGTH = 1500 # Characters per chunk
  AVAILABLE_VOICES = %w[alloy echo fable onyx nova shimmer].freeze

  def initialize(voice: 'echo')
    @voice = voice
    @openai_client = OpenAIClient.new
    validate_voice
  end

  # Generate audio from text
  def generate_audio(text, output_path: nil)
    chunks = split_text_for_tts(text)
    segment_files = []

    chunks.each_with_index do |chunk, index|
      audio_data = @openai_client.text_to_speech(chunk, voice: @voice)
      next unless audio_data

      temp_file = "temp_segment_#{format('%03d', index)}.mp3"
      File.binwrite(temp_file, audio_data)
      segment_files << temp_file
    end

    # Combine segments
    output_path ||= generate_output_path
    combine_segments(segment_files, output_path)

    # Cleanup
    cleanup_temp_files(segment_files)

    output_path
  rescue StandardError => e
    handle_error(e, operation: 'Generate audio')
  end

  # Process chat file and generate audio
  def process_chat_file(chat_content, output_path: nil)
    segments = extract_segments(chat_content)
    return nil if segments.empty?

    segment_files = []

    segments.each_with_index do |segment, seg_index|
      chunks = split_text_for_tts(segment)

      chunks.each_with_index do |chunk, chunk_index|
        audio_data = @openai_client.text_to_speech(chunk, voice: @voice)
        next unless audio_data

        temp_file = "temp_segment_#{format('%03d', seg_index)}_chunk_#{format('%03d', chunk_index)}.mp3"
        File.binwrite(temp_file, audio_data)
        segment_files << temp_file
      end
    end

    output_path ||= generate_output_path
    combine_segments(segment_files, output_path)
    cleanup_temp_files(segment_files)

    output_path
  rescue StandardError => e
    handle_error(e, operation: 'Process chat file')
  end

  private

  # Split text into manageable chunks for TTS
  def split_text_for_tts(text)
    return [text] if text.length <= MAX_CHUNK_LENGTH

    chunks = []
    start_index = 0

    while start_index < text.length
      if text.length - start_index <= MAX_CHUNK_LENGTH
        chunks << text[start_index..-1]
        break
      end

      chunk_length = find_chunk_end(text[start_index..-1], MAX_CHUNK_LENGTH)
      end_index = start_index + chunk_length
      chunk = text[start_index...end_index].strip
      chunks << chunk unless chunk.empty?
      start_index = end_index
    end

    chunks
  end

  # Find appropriate end position for chunk, preferring punctuation
  def find_chunk_end(text, max_length)
    return text.length if text.length <= max_length

    search_start = [max_length - 200, 0].max

    # Punctuation patterns in order of preference
    punctuation_patterns = [
      /\.\s/, /!\s/, /\?\s/,  # Sentence endings with space
      /;\s/, /:\s/, /,\s/,    # Other punctuation with space
      /\.\n/, /!\n/, /\?\n/,  # Sentence endings with newline
      /\n/, /\s/              # Newlines and spaces
    ]

    text_to_search = text[search_start...max_length]

    punctuation_patterns.each do |pattern|
      match = text_to_search.rindex(pattern)
      next unless match

      match_length = text_to_search[match..-1].match(pattern)[0].length
      return search_start + match + match_length
    end

    # Fallback: break at space near max_length
    space_before = text[0...max_length].rindex(' ')
    return space_before + 1 if space_before && space_before > max_length - 50

    max_length
  end

  # Extract segments from chat content
  def extract_segments(content)
    segments = []
    current_segment = ''

    content.each_line do |line|
      next if line.strip.empty? || line.include?('🤖 System:')

      # If line starts with role indicator, it's a new segment
      if line.match?(/^(🧑|👤|👩‍💻|🧔) (User|You):/) || line.match?(/^(🤖|🔮|💬) (Assistant|AI|ChatGPT):/)
        segments << current_segment unless current_segment.strip.empty?
        current_segment = line
      else
        current_segment += line
      end
    end

    segments << current_segment unless current_segment.strip.empty?
    segments
  end

  # Combine audio segments into single file
  def combine_segments(segment_files, output_file)
    sorted_files = sort_segment_files(segment_files)

    if system('which ffmpeg > /dev/null 2>&1')
      combine_with_ffmpeg(sorted_files, output_file)
    else
      combine_binary(sorted_files, output_file)
    end
  end

  # Combine using ffmpeg
  def combine_with_ffmpeg(sorted_files, output_file)
    list_file = 'segment_list.txt'
    File.open(list_file, 'w') do |file|
      sorted_files.each { |segment| file.puts "file '#{segment}'" }
    end

    system("ffmpeg -f concat -safe 0 -i #{list_file} -c copy #{output_file}")
    File.delete(list_file) if File.exist?(list_file)
  end

  # Combine by concatenating binary data
  def combine_binary(sorted_files, output_file)
    File.open(output_file, 'wb') do |output|
      sorted_files.each { |segment| output.write(File.binread(segment)) }
    end
  end

  # Sort segment files to ensure correct order
  def sort_segment_files(segment_files)
    segment_files.sort_by do |filename|
      if filename =~ /temp_segment_(\d+)_chunk_(\d+)/
        [$1.to_i, $2.to_i]
      elsif filename =~ /temp_segment_(\d+)/
        [$1.to_i, 0]
      else
        [Float::INFINITY, Float::INFINITY, filename]
      end
    end
  end

  # Clean up temporary files
  def cleanup_temp_files(files)
    files.each { |file| File.delete(file) if File.exist?(file) }
  end

  # Generate output path
  def generate_output_path
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    "audio_output/tts_#{timestamp}.mp3"
  end

  def validate_voice
    return if AVAILABLE_VOICES.include?(@voice)

    raise ArgumentError, "Invalid voice: #{@voice}. Must be one of: #{AVAILABLE_VOICES.join(', ')}"
  end
end

