#!/usr/bin/env ruby

require_relative 'v2/lib/tts_service'

# Create a test instance of the TTSService
tts_service = V2::TTSService.new

puts "Testing fixed TTS chunking implementation"
puts "----------------------------------------"

# Create a long text for testing (over 4096 characters)
long_text = "This is the first sentence of our test. " * 50
long_text += "This is the second type of sentence! " * 50
long_text += "Is this the third type of sentence? " * 50

puts "Original text length: #{long_text.length} characters"

# Split the text using our fixed method
chunks = tts_service.send(:split_text_for_tts, long_text)

puts "\nText was split into #{chunks.size} chunks:"
chunks.each_with_index do |chunk, i|
  puts "\nChunk #{i+1} (#{chunk.length} characters):"
  puts "#{chunk[0..50]}..." # Show the beginning of each chunk

  # Display the last 20 characters for inspection
  last_chars = chunk[-20..-1] || chunk
  puts "Last 20 chars: '#{last_chars}'"

  # Check for various punctuation patterns at the end
  if chunk =~ /[.!?;:,]\s*$/
    puts "✓ Ends with punctuation"
  else
    puts "✗ Does not end with punctuation"
  end

  # If not the last chunk, show the beginning of the next chunk to verify no overlap
  if i < chunks.size - 1
    next_chunk_start = chunks[i+1][0..50]
    puts "Next chunk starts with: '#{next_chunk_start}...'"

    # Check for actual overlap (not just similar content)
    # Get the last part of the current chunk and the first part of the next chunk
    last_50 = chunk[-50..-1] || chunk
    first_50 = chunks[i+1][0..50]

    # Print the exact strings we're comparing
    puts "End of current chunk: '#{last_50[-20..-1]}'"
    puts "Start of next chunk: '#{first_50[0..19]}'"

    # Check for actual overlap by comparing the end of one chunk with the beginning of the next
    # We'll look for overlapping text of at least 10 characters
    repeated_content = false

    # Check for overlapping text by sliding a window
    (10..30).each do |overlap_length|
      # Get the last N characters of the current chunk
      end_text = chunk[-overlap_length..-1]
      # Get the first N characters of the next chunk
      start_text = chunks[i+1][0...overlap_length]

      # If they match, we have duplication
      if end_text && start_text && end_text == start_text
        repeated_content = true
        puts "Found #{overlap_length} characters of duplicated text: '#{end_text}'"
        break
      end
    end

    if repeated_content
      puts "⚠️ Repeated content detected between chunks!"
    else
      puts "✓ No content duplication between chunks"
    end
  end
end

puts "\nAll chunks combined length: #{chunks.sum(&:length)} characters"

# Test the sorting of temporary files
puts "\nTesting file sorting:"
test_files = [
  "temp_segment_5_chunk_10.mp3",
  "temp_segment_001_chunk_002.mp3",
  "temp_segment_1_chunk_2.mp3",
  "temp_segment_10_chunk_1.mp3",
  "temp_segment_002_chunk_001.mp3",
  "some_other_file.mp3"
]

sorted_files = tts_service.send(:sort_segment_files, test_files)
puts "Original files: #{test_files.inspect}"
puts "Sorted files: #{sorted_files.inspect}"

puts "\nTest completed."
