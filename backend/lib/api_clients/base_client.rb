require 'net/http'
require 'json'
require 'uri'
require 'openssl'

# BaseApiClient - Base class for all API clients
# Provides common HTTP request handling, timeout configuration, error parsing, retry logic

class BaseApiClient
  attr_reader :api_key

  def initialize(api_key = nil)
    @api_key = api_key || load_api_key
  end

  # Load API key from environment variable
  # Subclasses should override if they need different behavior
  def load_api_key
    env_key = self.class::ENV_KEY
    ENV[env_key] || raise(StandardError, "#{env_key} not found in environment")
  end

  # Make a POST request to the API
  def post_request(url, headers, payload, max_retries: 3)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # SSL verification
    # In development, disable strict verification to avoid certificate chain issues
    if ENV['RACK_ENV'] == 'development' || ENV['RACK_ENV'].nil?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      # Production: strict verification
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    # Set reasonable timeouts
    # For AI operations (like Venice chat completions), use longer timeouts
    # since AI responses can take 30-60+ seconds for complex requests
    http.open_timeout = 10
    http.read_timeout = ENV.fetch('AI_READ_TIMEOUT', '480').to_i  # Default 480 seconds (8 minutes) for AI operations
    http.write_timeout = 10 if http.respond_to?(:write_timeout=)

    # Enable debugging if requested
    http.set_debug_output($stdout) if ENV['HTTP_DEBUG']

    request = Net::HTTP::Post.new(uri)
    headers.each { |key, value| request[key] = value }
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    retries = 0
    begin
      response = http.request(request)
      
      # Log response details for debugging if there's an error
      if response.code.to_i >= 400 || (response.body && response.body.start_with?('<!DOCTYPE', '<html', '<HTML'))
        puts "API Error Response (#{url}):"
        puts "  Status: #{response.code} #{response.message}"
        puts "  Content-Type: #{response['Content-Type']}"
        puts "  Body preview: #{response.body ? response.body[0..500] : '(empty)'}"
      end
      
      parse_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retries += 1
      if retries <= max_retries
        sleep(retries) # Exponential backoff
        retry
      else
        { 'error' => { 'message' => "Request timed out after #{max_retries} retries: #{e.message}" } }
      end
    rescue Interrupt
      { 'error' => { 'message' => 'Request interrupted by user' } }
    rescue StandardError => e
      { 'error' => { 'message' => "API request error: #{e.message}" } }
    end
  end

  # Make a GET request to the API
  def get_request(url, headers, max_retries: 3)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    http.open_timeout = 10
    http.read_timeout = ENV.fetch('AI_READ_TIMEOUT', '480').to_i  # Default 480 seconds (8 minutes) for AI operations

    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }

    retries = 0
    begin
      response = http.request(request)
      parse_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retries += 1
      if retries <= max_retries
        sleep(retries)
        retry
      else
        { 'error' => { 'message' => "Request timed out after #{max_retries} retries: #{e.message}" } }
      end
    rescue StandardError => e
      { 'error' => { 'message' => "API request error: #{e.message}" } }
    end
  end

  private

  # Parse API response
  def parse_response(response)
    # Check if response body exists
    unless response.body
      return { 'error' => { 'message' => "API returned empty response. Status: #{response.code}" } }
    end

    # Check if response is HTML (error page) instead of JSON
    if response.body.start_with?('<!DOCTYPE', '<html', '<HTML')
      error_msg = "API returned HTML instead of JSON. Status: #{response.code} #{response.message}. "
      # Try to extract error message from HTML if possible
      if response.body.include?('<title>')
        title_match = response.body.match(/<title>(.*?)<\/title>/i)
        error_msg += "Page title: #{title_match[1]} " if title_match
      end
      error_msg += "Response preview: #{response.body[0..300]}"
      return { 
        'error' => { 
          'message' => error_msg,
          'html_content' => response.body,
          'is_html' => true
        } 
      }
    end

    parsed = JSON.parse(response.body)

    if response.code.to_i >= 400
      error_message = extract_error_message(parsed, response)
      { 'error' => { 'message' => error_message } }
    else
      parsed
    end
  rescue JSON::ParserError => e
    error_msg = "Failed to parse API response: #{e.message}"
    error_msg += ". Response preview: #{response.body[0..200]}" if response.body
    { 'error' => { 'message' => error_msg } }
  end

  # Extract error message from response
  def extract_error_message(parsed, response)
    if parsed['error'] && parsed['error']['message']
      parsed['error']['message']
    elsif parsed['message']
      parsed['message']
    else
      "API returned error status: #{response.code} #{response.message}"
    end
  end
end

