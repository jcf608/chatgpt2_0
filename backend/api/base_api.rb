require 'sinatra/base'
require 'json'

# BaseAPI - Base class for all API endpoints
# Provides common functionality: JSON responses, error handling, request validation

class BaseAPI < Sinatra::Base
  # JSON response helper
  def json_response(data, status: 200)
    content_type :json
    status status
    
    response = {
      success: status < 400,
      data: data,
      timestamp: Time.now.iso8601
    }
    
    response.to_json
  rescue StandardError => e
    error_response("Failed to generate response: #{e.message}", status: 500)
  end

  # Error response helper
  def error_response(message, code: nil, details: {}, status: 400)
    content_type :json
    status status

    response = {
      success: false,
      error: {
        message: message,
        code: code || error_code_for_status(status),
        details: details
      },
      timestamp: Time.now.iso8601
    }

    response.to_json
  rescue StandardError => e
    {
      success: false,
      error: {
        message: "Failed to generate error response: #{e.message}",
        code: 'INTERNAL_ERROR'
      },
      timestamp: Time.now.iso8601
    }.to_json
  end

  # Success response helper
  def success_response(data, status: 200)
    json_response(data, status: status)
  end

  # Parse JSON request body
  def parse_json_body
    body = request.body.read
    return {} if body.empty?

    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError => e
    raise ArgumentError, "Invalid JSON: #{e.message}"
  end

  # Validate required parameters
  def validate_required(params, *required_keys)
    missing = required_keys.reject { |key| params.key?(key) && !params[key].nil? && params[key] != '' }
    
    if missing.any?
      raise ArgumentError, "Missing required parameters: #{missing.join(', ')}"
    end
  end

  # Handle errors
  error ArgumentError do
    error_response(env['sinatra.error'].message, code: 'VALIDATION_ERROR', status: 400)
  end

  error StandardError do
    error_msg = env['sinatra.error'].message
    error_response(error_msg, code: 'INTERNAL_ERROR', status: 500)
  end

  error 404 do
    error_response('Resource not found', code: 'NOT_FOUND', status: 404)
  end

  error 500 do
    error_response('Internal server error', code: 'INTERNAL_ERROR', status: 500)
  end

  private

  def error_code_for_status(status)
    case status
    when 400 then 'BAD_REQUEST'
    when 401 then 'UNAUTHORIZED'
    when 403 then 'FORBIDDEN'
    when 404 then 'NOT_FOUND'
    when 422 then 'UNPROCESSABLE_ENTITY'
    when 500 then 'INTERNAL_ERROR'
    else 'ERROR'
    end
  end
end

