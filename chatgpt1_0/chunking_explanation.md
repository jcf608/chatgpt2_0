# Text Chunking in the TTS Service

## Overview

The Text-to-Speech (TTS) service in this project handles large texts by breaking them into smaller, manageable chunks before sending them to the OpenAI API for speech synthesis. This document explains how the chunking process works and how the audio segments are combined to create a seamless listening experience.

## Chunking Process

### 1. Initial Text Processing

When a text is submitted for speech synthesis, the system first checks if it exceeds the maximum length limit (default: 1500 characters). If the text is within the limit, it's processed as a single chunk. If it exceeds the limit, the chunking process begins.

```ruby
def split_text_for_tts(text, max_length = 1500)
  return [text] if text.length <= max_length
  
  # Chunking logic follows...
end
```

### 2. Intelligent Chunk Boundaries

The system doesn't simply split text at arbitrary character positions. Instead, it looks for natural breaking points such as sentence endings, commas, or other punctuation marks. This ensures that each chunk ends at a logical point in the text, which results in more natural-sounding speech when the audio segments are played sequentially.

The chunking algorithm works as follows:

1. Start from the beginning of the text
2. For each chunk, find an appropriate end position near the maximum length limit
3. Extract the chunk and add it to the result
4. Move the starting position to the end of the current chunk
5. Repeat until the entire text has been processed

```ruby
while start_index < text.length
  # If remaining text is shorter than max_length, add it as the final chunk
  if text.length - start_index <= max_length
    chunks << text[start_index..-1]
    break
  end

  # Find a good breaking point near the max_length
  chunk_length = find_chunk_end(text[start_index..-1], max_length) 
  
  # Calculate the absolute end position
  end_index = start_index + chunk_length

  # Extract the chunk and add it to the result
  chunk = text[start_index...end_index].strip
  chunks << chunk unless chunk.empty?

  # Update the start index for the next chunk
  start_index = end_index
end
```

### 3. Finding Optimal Break Points

The `find_chunk_end` method is responsible for determining where each chunk should end. It prioritizes different types of punctuation marks in the following order:

1. Sentence endings with space (`. `, `! `, `? `)
2. Other punctuation with space (`;`, `:`, `,`)
3. Sentence endings with newline (`.\n`, `!\n`, `?\n`)
4. Newlines and spaces as a last resort

The method searches for these punctuation patterns within a reasonable range before the maximum length limit. If no suitable punctuation is found, it falls back to breaking at a space near the maximum length, or as a last resort, exactly at the maximum length.

```ruby
def find_chunk_end(text, max_length)
  # If text is shorter than max_length, return its length
  return text.length if text.length <= max_length

  # Look for punctuation marks within a reasonable range before max_length
  search_start = [max_length - 200, 0].max

  # Define punctuation patterns in order of preference
  punctuation_patterns = [
    /\.\s/, /!\s/, /\?\s/,  # Sentence endings with space
    /;\s/, /:\s/, /,\s/,    # Other punctuation with space
    /\.\n/, /!\n/, /\?\n/,  # Sentence endings with newline
    /\n/, /\s/              # Newlines and spaces as last resort
  ]

  # Try each punctuation pattern
  punctuation_patterns.each do |pattern|
    text_to_search = text[search_start...max_length]
    match = text_to_search.rindex(pattern)
    if match
      match_length = text_to_search[match..-1].match(pattern)[0].length
      return search_start + match + match_length
    end
  end

  # Fallback options if no punctuation found
  space_before = text[0...max_length].rindex(' ')
  return space_before + 1 if space_before && space_before > max_length - 50

  # Last resort: break exactly at max_length
  return max_length
end
```

## Audio Processing

### 1. Generating Audio for Each Chunk

Once the text has been split into chunks, the system processes each chunk sequentially:

1. Each chunk is sent to the OpenAI TTS API
2. The resulting audio data is saved to a temporary file
3. The temporary file path is added to a list for later processing

```ruby
chunks.each_with_index do |chunk, chunk_index|
  puts "Sending chunk #{chunk_index + 1}/#{chunks.size} (#{chunk.length} characters) to the server..."
  
  temp_file = "temp_segment_%03d_chunk_%03d.mp3" % [index, chunk_index]
  audio_data = @client.text_to_speech(chunk, voice: @voice)
  
  # Skip if audio generation failed
  if audio_data.nil?
    puts "Skipping chunk #{chunk_index + 1} due to persistent errors."
    next
  end
  
  File.open(temp_file, 'wb') { |file| file.write(audio_data) }
  segment_files << temp_file
end
```

### 2. Combining Audio Segments

After all chunks have been processed, the system combines the individual audio segments into a single audio file. This is done using one of two methods:

1. **FFmpeg Method**: If FFmpeg is available on the system, it's used to concatenate the audio files. This is the preferred method as it ensures seamless transitions between segments.

2. **Binary Concatenation**: If FFmpeg is not available, the system falls back to binary concatenation, which simply appends the binary data of each audio file to create a single file.

```ruby
def combine_segments(segment_files, output_file)
  if system("which ffmpeg > /dev/null 2>&1")
    combine_with_ffmpeg(segment_files, output_file)
  else
    combine_binary(segment_files, output_file)
  end
end
```

### 3. Ensuring Correct Segment Order

To ensure that the audio segments are combined in the correct order, the system sorts the temporary files based on their segment and chunk indices:

```ruby
def sort_segment_files(segment_files)
  segment_files.sort_by do |filename|
    if filename =~ /temp_segment_(\d+)_chunk_(\d+)/
      # Sort by segment index first, then by chunk index
      [$1.to_i, $2.to_i]
    else
      # For other filename formats, just use the filename itself
      [Float::INFINITY, Float::INFINITY, filename]
    end
  end
end
```

## Conclusion

The chunking process in the TTS service is designed to handle large texts efficiently while maintaining natural speech patterns. By intelligently splitting text at appropriate punctuation marks and ensuring correct ordering of audio segments, the system produces high-quality speech synthesis even for very long texts.

The process preserves the sequence of the original text and avoids duplication or out-of-order segments, resulting in a seamless listening experience for the user.