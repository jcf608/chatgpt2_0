require 'net/http'
require 'json'
require 'uri'

module V2
  # Base class for API clients
  class ApiClient
    attr_reader :api_key

    def initialize(api_key = nil)
      @api_key = api_key || load_api_key
    end

    # Load API key from file or environment variable
    def load_api_key
      raise NotImplementedError, "Subclasses must implement load_api_key"
    end

    # Make a POST request to the API
    def post_request(url, headers, payload)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      # Set reasonable timeouts to prevent hanging
      http.open_timeout = 10  # seconds
      http.read_timeout = 30  # seconds
      http.write_timeout = 10 if http.respond_to?(:write_timeout=)  # seconds, Ruby 2.6+

      # Enable debugging for HTTP requests
      http.set_debug_output($stdout) if ENV['HTTP_DEBUG']

      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      begin
        response = http.request(request)

        begin
          parsed_response = JSON.parse(response.body)

          # Check if the response contains an error
          if response.code.to_i >= 400
            error_message = if parsed_response['error'] && parsed_response['error']['message']
                             parsed_response['error']['message']
                           elsif parsed_response['message']
                             parsed_response['message']
                           else
                             "API returned error status: #{response.code} #{response.message}"
                           end
            { 'error' => { 'message' => error_message } }
          else
            parsed_response
          end
        rescue JSON::ParserError => e
          { 'error' => { 'message' => "Failed to parse API response: #{e.message}" } }
        end
      rescue Net::OpenTimeout
        { 'error' => { 'message' => "Connection timed out. Please check your internet connection and try again." } }
      rescue Net::ReadTimeout
        { 'error' => { 'message' => "Request timed out. The server took too long to respond." } }
      rescue Interrupt
        { 'error' => { 'message' => "Request interrupted by user." } }
      rescue StandardError => e
        { 'error' => { 'message' => "API request error: #{e.message}" } }
      end
    end
  end
end
