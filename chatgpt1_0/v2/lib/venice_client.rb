require_relative 'api_client'

module V2
  # Venice API client
  class VeniceClient < ApiClient
    VENICE_API_URL = "https://api.venice.ai/api/v1/chat/completions"
    VENICE_IMAGE_API_URL = "https://api.venice.ai/api/v1/images/generations"

    def initialize(api_key = nil)
      super(api_key)
    end

    # Load Venice API key from file or environment variable
    def load_api_key
      if ENV['VENICE_API_KEY']
        ENV['VENICE_API_KEY']
      elsif File.exist?('venice_api_key')
        api_key = File.read('venice_api_key').strip
        api_key
      else
        puts "Error: Venice API key not found. Please set VENICE_API_KEY environment variable or create a 'venice_api_key' file."
        exit 1
      end
    end

    # Send a chat completion request to Venice
    def chat_completion(messages, model: "llama-3.3-70b", max_tokens: 1000, temperature: 0.7)
      # Check if API key is available
      if @api_key.nil? || @api_key.empty?
        return { 'error' => { 'message' => 'Venice API key not found. Please set VENICE_API_KEY environment variable or create a venice_api_key file in the project root.' } }
      end

      begin
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

        response = post_request(VENICE_API_URL, headers, payload)
        response
      rescue => e
        { 'error' => { 'message' => "Venice API error: #{e.message}" } }
      end
    end

    # Generate an image from a prompt using Venice
    def generate_image(prompt, style: nil, width: 1024, height: 1024, n: 1)
      headers = { 'Authorization' => "Bearer #{@api_key}" }

      payload = {
        prompt: prompt,
        n: n,
        width: width,
        height: height
      }

      # Add style if provided
      payload[:style] = style if style

      post_request(VENICE_IMAGE_API_URL, headers, payload)
    end
  end
end
