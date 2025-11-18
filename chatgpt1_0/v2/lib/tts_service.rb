require 'fileutils'
require_relative 'openai_client'

module V2
  # Text-to-speech service
  class TTSService
    AVAILABLE_VOICES = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]

    attr_reader :client, :voice

    def initialize(voice: "echo", api_key: nil)
      @voice = voice
      @client = OpenAIClient.new(api_key)
    end

    # Speak text using OpenAI TTS
    def speak_text(text)
      # Split text into manageable chunks if it's too long
      chunks = split_text_for_tts(text)

      # Generate audio for each chunk
      chunks.each_with_index do |chunk, index|
        begin
          puts "Sending chunk #{index + 1}/#{chunks.size} (#{chunk.length} characters) to the server..."
          audio_data = @client.text_to_speech(chunk, voice: @voice)

          # Skip if audio generation failed
          next if audio_data.nil?

          # Create a temporary file for the audio
          temp_file = "temp_speech_#{Time.now.to_i}.mp3"
          File.open(temp_file, 'wb') { |file| file.write(audio_data) }

          # Play the audio using system command
          system_play_audio(temp_file)

          # Clean up the temporary file
          File.delete(temp_file) if File.exist?(temp_file)
        rescue Interrupt
          puts "\nText-to-speech process interrupted."
          break  # Exit the loop on interrupt
        rescue StandardError => e
          puts "\nError in text-to-speech process: #{e.message}"
          next  # Try the next chunk on error
        end
      end
    end

    # Process a chat file and generate audio
    def process_chat_file(file_path, output_name = nil)
      unless File.exist?(file_path)
        puts "Error: File not found: #{file_path}"
        return
      end

      content = File.read(file_path)
      segments = extract_segments(content)

      if segments.empty?
        puts "No valid segments found in the file."
        return
      end

      # Create output directory if it doesn't exist
      FileUtils.mkdir_p('audio_output') unless Dir.exist?('audio_output')

      # Generate output filename if not provided
      if output_name.nil?
        base_name = File.basename(file_path, '.*')
        output_name = "audio_output/#{base_name}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.mp3"
      else
        output_name = "audio_output/#{output_name}.mp3" unless output_name.include?('/')
      end

      # Generate audio for each segment
      segment_files = []
      segments.each_with_index do |segment, index|
        puts "Processing segment #{index + 1}/#{segments.size}..."

        # Split segment into chunks if it exceeds the character limit
        chunks = split_text_for_tts(segment)

        # Process each chunk
        chunks.each_with_index do |chunk, chunk_index|
          puts "Sending chunk #{chunk_index + 1}/#{chunks.size} (#{chunk.length} characters) to the server..."

          # Ensure consistent naming format for proper sorting
          # Use zero-padding for indices to ensure correct string sorting
          temp_file = "temp_segment_%03d_chunk_%03d.mp3" % [index, chunk_index]
          audio_data = @client.text_to_speech(chunk, voice: @voice)

          # Skip if audio generation failed after all retries
          if audio_data.nil?
            puts "Skipping chunk #{chunk_index + 1} of segment #{index + 1} due to persistent errors."
            next
          end

          File.open(temp_file, 'wb') { |file| file.write(audio_data) }
          segment_files << temp_file
        end
      end

      # Combine all segments into a single audio file
      combine_segments(segment_files, output_name)

      # Clean up temporary files
      cleanup_temp_files(segment_files)

      puts "Audio saved to: #{output_name}"
      output_name
    end

    # Extract segments from chat content
    def extract_segments(content)
      segments = []
      current_segment = ""

      content.each_line do |line|
        # Skip empty lines and system messages
        next if line.strip.empty? || line.include?("🤖 System:")

        # If line starts with a role indicator, it's a new segment
        if line.match?(/^(🧑|👤|👩‍💻|🧔) (User|You):/) || line.match?(/^(🤖|🔮|💬) (Assistant|AI|ChatGPT):/)
          # Save the previous segment if it's not empty
          segments << current_segment unless current_segment.strip.empty?
          current_segment = line
        else
          current_segment += line
        end
      end

      # Add the last segment
      segments << current_segment unless current_segment.strip.empty?

      segments
    end

    # Combine audio segments into a single file
    def combine_segments(segment_files, output_file)
      if system("which ffmpeg > /dev/null 2>&1")
        combine_with_ffmpeg(segment_files, output_file)
      else
        combine_binary(segment_files, output_file)
      end
    end

    # Combine audio segments using ffmpeg
    def combine_with_ffmpeg(segment_files, output_file)
      # Sort segment files to ensure correct order
      sorted_files = sort_segment_files(segment_files)

      # Create a text file listing all segments
      list_file = "segment_list.txt"
      File.open(list_file, "w") do |file|
        sorted_files.each do |segment|
          file.puts "file '#{segment}'"
        end
      end

      # Use ffmpeg to concatenate the files
      system("ffmpeg -f concat -safe 0 -i #{list_file} -c copy #{output_file}")

      # Clean up the list file
      File.delete(list_file) if File.exist?(list_file)
    end

    # Combine audio segments by concatenating binary data
    def combine_binary(segment_files, output_file)
      # Sort segment files to ensure correct order
      sorted_files = sort_segment_files(segment_files)

      File.open(output_file, "wb") do |output|
        sorted_files.each do |segment|
          output.write(File.binread(segment))
        end
      end
    end

    # Sort segment files to ensure they are processed in the correct order
    def sort_segment_files(segment_files)
      segment_files.sort_by do |filename|
        # Extract segment and chunk indices from filenames
        # Handles both old format "temp_segment_0_chunk_1.mp3" and new format "temp_segment_001_chunk_002.mp3"
        if filename =~ /temp_segment_(\d+)_chunk_(\d+)/
          # Sort by segment index first, then by chunk index
          [$1.to_i, $2.to_i]
        else
          # For other filename formats, just use the filename itself
          [Float::INFINITY, Float::INFINITY, filename]
        end
      end
    end

    # Clean up temporary files
    def cleanup_temp_files(files)
      files.each do |file|
        File.delete(file) if File.exist?(file)
      end
    end

    # Split text into manageable chunks for TTS
    def split_text_for_tts(text, max_length = 1500)
      return [text] if text.length <= max_length

      puts "Text is too long (#{text.length} characters). Splitting into smaller chunks..."

      chunks = []
      remaining_text = text
      start_index = 0

      while start_index < text.length
        # If remaining text is shorter than max_length, add it as the final chunk
        if text.length - start_index <= max_length
          chunks << text[start_index..-1]
          break
        end

        # Find a good breaking point (punctuation mark) near the max_length
        chunk_length = find_chunk_end(text[start_index..-1], max_length) 

        # Calculate the absolute end position
        end_index = start_index + chunk_length

        # Extract the chunk and add it to the result
        chunk = text[start_index...end_index].strip
        chunks << chunk unless chunk.empty?

        # Update the start index for the next chunk
        start_index = end_index
      end

      chunks
    end

    # Find an appropriate end position for a chunk, preferring punctuation marks
    def find_chunk_end(text, max_length)
      # If text is shorter than max_length, return its length
      return text.length if text.length <= max_length

      # Look for punctuation marks within a reasonable range before max_length
      # Start from max_length and work backwards to find a good breaking point
      search_start = [max_length - 200, 0].max

      # Define punctuation marks in order of preference (with their following space if applicable)
      punctuation_patterns = [
        /\.\s/, /!\s/, /\?\s/,  # Sentence endings with space
        /;\s/, /:\s/, /,\s/,    # Other punctuation with space
        /\.\n/, /!\n/, /\?\n/,  # Sentence endings with newline
        /\n/, /\s/              # Newlines and spaces as last resort
      ]

      # Try each punctuation pattern, but only search backwards from max_length
      punctuation_patterns.each do |pattern|
        # Search backwards from max_length for this punctuation
        text_to_search = text[search_start...max_length]
        match = text_to_search.rindex(pattern)
        if match
          # Find the end of the match
          match_length = text_to_search[match..-1].match(pattern)[0].length
          return search_start + match + match_length
        end
      end

      # If no punctuation found, just break at max_length or at a space near it
      space_before = text[0...max_length].rindex(' ')
      return space_before + 1 if space_before && space_before > max_length - 50

      # Last resort: break exactly at max_length
      return max_length
    end

    private

    # Play audio using system command
    def system_play_audio(file)
      begin
        case RbConfig::CONFIG['host_os']
        when /darwin/
          system("afplay #{file}")
        when /linux/
          system("aplay #{file}")
        when /mswin|mingw/
          system("start #{file}")
        else
          puts "Audio playback not supported on this platform. File saved to: #{file}"
        end
      rescue Interrupt
        # Gracefully handle CTRL+C interruption
        puts "\nAudio playback interrupted."
      end
    end
  end
end
