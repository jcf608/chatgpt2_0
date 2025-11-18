require_relative 'base_service'
require_relative '../lib/api_clients/venice_client'
require_relative '../lib/api_clients/openai_client'

# AIService - Factory pattern for AI provider selection
# Default: Venice.ai for chat completions
# OpenAI: Optional for chat, but NOT used (TTS only)

class AIService < BaseService
  DEFAULT_PROVIDER = 'venice'
  AVAILABLE_PROVIDERS = %w[venice openai].freeze

  def initialize(provider: DEFAULT_PROVIDER)
    @provider = provider || DEFAULT_PROVIDER
    validate_provider
  end

  # Send message to AI (system prompts go to selected provider)
  def send_message(messages, max_tokens: 1000, temperature: 0.7)
    client = get_client
    response = client.chat_completion(messages, max_tokens: max_tokens, temperature: temperature)
    
    # Log response for debugging
    if response['error']
      puts "AI Service Error: #{response['error']}"
    end
    
    response
  rescue StandardError => e
    puts "AI Service Exception: #{e.class}: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    # Return error hash instead of raising
    { 'error' => { 'message' => "Send message to AI failed: #{e.message}" } }
  end

  # Extended dialogue generation - multi-segment generation with word count tracking
  def generate_extended_dialogue(messages, target_words:, progress_callback: nil)
    current_words = count_words_in_messages(messages)
    segments = []
    segment_count = 0

    loop do
      break if current_words >= target_words

      segment_count += 1
      continuation_prompt = generate_continuation_prompt(segments.last, target_words - current_words)

      # Add continuation prompt to messages
      extended_messages = messages.dup
      extended_messages << { role: 'user', content: continuation_prompt }

      # Get AI response
      response = send_message(extended_messages)
      break if response['error']

      segment_text = extract_response_text(response)
      segments << segment_text
      extended_messages << { role: 'assistant', content: segment_text }

      segment_words = count_words(segment_text)
      current_words += segment_words

      # Call progress callback if provided
      progress_callback&.call(segment_count, segment_words, current_words, target_words)

      # Update messages for next iteration
      messages = extended_messages

      sleep(1) # Brief pause between segments
    end

    { segments: segments, total_words: current_words, segment_count: segment_count }
  rescue Interrupt
    { segments: segments, total_words: current_words, segment_count: segment_count, interrupted: true }
  rescue StandardError => e
    handle_error(e, operation: 'Generate extended dialogue')
  end

  # Continue conversation - add words to existing conversation
  def continue_conversation(messages, additional_words:, user_prompt: nil)
    current_words = count_words_in_messages(messages)

    continuation_prompt = if user_prompt
                           "#{user_prompt} Continue the dialogue naturally, maintaining character consistency."
                         else
                           'Continue the dialogue naturally from where we left off. Maintain character consistency.'
                         end

    generate_extended_dialogue(
      messages,
      target_words: current_words + additional_words,
      progress_callback: ->(seg, seg_words, curr_words, target) do
        puts "Segment #{seg}: +#{seg_words} words, Total: #{curr_words}/#{target}"
      end
    )
  end

  private

  def get_client
    case @provider
    when 'venice'
      @venice_client ||= VeniceClient.new
    when 'openai'
      # Note: OpenAI chat completion is optional, Venice is default
      # This is here for flexibility, but Venice should be preferred
      raise StandardError, 'OpenAI chat completion not implemented. Use Venice for chat.'
    else
      raise ArgumentError, "Unknown provider: #{@provider}"
    end
  end

  def validate_provider
    return if AVAILABLE_PROVIDERS.include?(@provider)

    raise ArgumentError, "Invalid provider: #{@provider}. Must be one of: #{AVAILABLE_PROVIDERS.join(', ')}"
  end

  def extract_response_text(response)
    return '' if response['error']

    if response['choices'] && response['choices'][0] && response['choices'][0]['message']
      response['choices'][0]['message']['content']
    else
      ''
    end
  end

  def generate_continuation_prompt(previous_segment, remaining_words)
    base_prompts = [
      'Continue the dialogue naturally, building on the previous exchange. Maintain character consistency.',
      'Keep the conversation flowing with detailed exchanges. Focus on character development.',
      'Continue with immersive dialogue that advances the relationship and story.',
      'Develop the scene further with engaging dialogue that deepens the connection.'
    ]

    base = base_prompts.sample
    word_guidance = remaining_words > 500 ? 'Generate substantial content.' : 'Begin wrapping up naturally.'

    "#{base} #{word_guidance}"
  end

  def count_words_in_messages(messages)
    messages.reject { |m| m[:role] == 'system' || m['role'] == 'system' }
            .sum { |m| count_words(m[:content] || m['content'] || '') }
  end

  def count_words(text)
    text.split(/\s+/).reject(&:empty?).length
  end
end

