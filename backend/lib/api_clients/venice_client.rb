require_relative 'base_client'

# VeniceClient - Client for Venice.ai API
# Primary/default provider for chat completions and system prompts

class VeniceClient < BaseApiClient
  ENV_KEY = 'VENICE_API_KEY'
  VENICE_API_URL = 'https://api.venice.ai/api/v1/chat/completions'
  VENICE_IMAGE_API_URL = 'https://api.venice.ai/api/v1/images/generations'

  # Send a chat completion request to Venice
  def chat_completion(messages, model: 'llama-3.3-70b', max_tokens: 1000, temperature: 0.7)
    ensure_configured!

    headers = { 'Authorization' => "Bearer #{@api_key}" }
    payload = {
      model: model,
      messages: messages,
      max_tokens: max_tokens,
      temperature: temperature,
      venice_parameters: {
        include_venice_system_prompt: false,
        top_p: 0.9,
        repetition_penalty: 1.1
      }
    }

    post_request(VENICE_API_URL, headers, payload)
  end

  # Generate an image from a prompt using Venice
  def generate_image(prompt, style: nil, width: 1024, height: 1024, n: 1)
    ensure_configured!

    headers = { 'Authorization' => "Bearer #{@api_key}" }
    payload = {
      prompt: prompt,
      n: n,
      width: width,
      height: height
    }

    payload[:style] = style if style

    post_request(VENICE_IMAGE_API_URL, headers, payload)
  end

  private

  # Ensure API key is configured (lazy loading pattern from PRINCIPLES.md)
  def ensure_configured!
    return if @api_key && !@api_key.empty?

    raise StandardError, 'Venice API key not configured. Set VENICE_API_KEY environment variable.'
  end
end

