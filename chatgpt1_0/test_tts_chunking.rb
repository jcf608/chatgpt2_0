#!/usr/bin/env ruby

require_relative 'v2/lib/tts_service'

# Create a test instance of the TTSService
tts_service = V2::TTSService.new

# Create a long text for testing (over 4096 characters)
long_text = "This is the first sentence of our test. " * 100
long_text += "This is the second type of sentence! " * 100
long_text += "Is this the third type of sentence? " * 100

puts "Original text length: #{long_text.length} characters"

# Split the text using our new method
chunks = tts_service.send(:split_text_for_tts, long_text)

puts "\nText was split into #{chunks.size} chunks:"
chunks.each_with_index do |chunk, i|
  puts "\nChunk #{i+1} (#{chunk.length} characters):"
  puts "#{chunk[0..100]}..." # Show the beginning of each chunk

  # Check if the chunk ends with a punctuation mark
  # Display the last 20 characters for inspection
  last_chars = chunk[-20..-1] || chunk
  puts "Last 20 chars: '#{last_chars}'"

  # Check for various punctuation patterns at the end
  if chunk =~ /[.!?;:,]\s*$/
    puts "✓ Ends with punctuation"
  else
    puts "✗ Does not end with punctuation"
  end
end

puts "\nAll chunks combined length: #{chunks.sum(&:length)} characters"
