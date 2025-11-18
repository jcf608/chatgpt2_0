require_relative 'api_client'

module V2
  # OpenAI API client
  class OpenAIClient < ApiClient
    OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
    OPENAI_TTS_API_URL = "https://api.openai.com/v1/audio/speech"
    OPENAI_IMAGE_API_URL = "https://api.openai.com/v1/images/generations"

    def initialize(api_key = nil)
      super(api_key)
    end

    # Load OpenAI API key from file or environment variable
    def load_api_key
      if ENV['OPENAI_API_KEY']
        ENV['OPENAI_API_KEY']
      elsif File.exist?('openAI_api_key')
        File.read('openAI_api_key').strip
      else
        puts "Error: OpenAI API key not found. Please set OPENAI_API_KEY environment variable or create an 'openAI_api_key' file."
        exit 1
      end
    end

    # Send a chat completion request to OpenAI
    def chat_completion(messages, model: "gpt-3.5-turbo", max_tokens: 1000, temperature: 0.7)
      headers = { 'Authorization' => "Bearer #{@api_key}" }
      payload = {
        model: model,
        messages: messages,
        max_tokens: max_tokens,
        temperature: temperature
      }

      post_request(OPENAI_API_URL, headers, payload)
    end

    # Generate speech from text using OpenAI TTS
    def text_to_speech(text, voice: "alloy", output_format: "mp3", speed: 1.0, model: "tts-1", max_retries: 10)
      uri = URI(OPENAI_TTS_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30  # Set a reasonable timeout

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
        puts "Sending request to OpenAI TTS API..."
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
          puts "\nNetwork timeout while generating speech. Retrying (#{retries}/#{max_retries})..."
          sleep(1 * retries)  # Exponential backoff
          retry
        else
          puts "\nNetwork timeout while generating speech. Maximum retries (#{max_retries}) exceeded. Please try again later."
          nil
        end
      rescue Interrupt
        puts "\nSpeech generation interrupted."
        nil
      rescue StandardError => e
        retries += 1
        if retries <= max_retries
          puts "\nError during speech generation: #{e.message}. Retrying (#{retries}/#{max_retries})..."
          sleep(1 * retries)  # Exponential backoff
          retry
        else
          puts "\nError during speech generation: #{e.message}. Maximum retries (#{max_retries}) exceeded. Please try again later."
          nil
        end
      end
    end

    # Generate an image from a prompt using OpenAI DALL-E
    def generate_image(prompt, size: "1024x1024", n: 1, model: "dall-e-3")
      headers = { 'Authorization' => "Bearer #{@api_key}" }
      payload = {
        model: model,
        prompt: prompt,
        n: n,
        size: size,
        response_format: "url"
      }

      post_request(OPENAI_IMAGE_API_URL, headers, payload)
    end
  end
end
