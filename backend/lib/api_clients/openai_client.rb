require_relative 'base_client'
require 'net/http'
require 'json'
require 'uri'

# OpenAIClient - Client for OpenAI API
# Used EXCLUSIVELY for text-to-speech (not chat completion)
# TTS always uses OpenAI regardless of chat provider

class OpenAIClient < BaseApiClient
  ENV_KEY = 'OPENAI_API_KEY'
  OPENAI_TTS_API_URL = 'https://api.openai.com/v1/audio/speech'
  OPENAI_IMAGE_API_URL = 'https://api.openai.com/v1/images/generations'

  AVAILABLE_VOICES = %w[alloy echo fable onyx nova shimmer].freeze

  # Generate speech from text using OpenAI TTS
  # This is the PRIMARY method - OpenAI is used ONLY for TTS
  def text_to_speech(text, voice: 'echo', output_format: 'mp3', speed: 1.0, model: 'tts-1', max_retries: 10)
    ensure_configured!

    uri = URI(OPENAI_TTS_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'

    payload = {
      model: model,
      input: text,
      voice: voice,
      response_format: output_format,
      speed: speed
    }

    request.body = payload.to_json

    retries = 0
    begin
      response = http.request(request)

      if response.code == '200'
        response.body
      else
        error = JSON.parse(response.body)
        raise "TTS Error: #{error['error']['message']}"
      end
    rescue Net::ReadTimeout
      retries += 1
      if retries <= max_retries
        sleep(retries) # Exponential backoff
        retry
      else
        raise StandardError, "TTS request timed out after #{max_retries} retries"
      end
    rescue Interrupt
      raise StandardError, 'TTS generation interrupted'
    rescue StandardError => e
      retries += 1
      if retries <= max_retries
        sleep(retries)
        retry
      else
        raise StandardError, "TTS generation failed: #{e.message}"
      end
    end
  end

  # Generate an image from a prompt using OpenAI DALL-E
  def generate_image(prompt, size: '1024x1024', n: 1, model: 'dall-e-3')
    ensure_configured!

    headers = { 'Authorization' => "Bearer #{@api_key}" }
    payload = {
      model: model,
      prompt: prompt,
      n: n,
      size: size,
      response_format: 'url'
    }

    post_request(OPENAI_IMAGE_API_URL, headers, payload)
  end

  private

  # Ensure API key is configured (lazy loading pattern)
  def ensure_configured!
    return if @api_key && !@api_key.empty?

    raise StandardError, 'OpenAI API key not configured. Set OPENAI_API_KEY environment variable.'
  end
end

