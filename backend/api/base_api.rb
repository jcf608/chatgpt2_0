require 'sinatra/base'
require 'json'
require 'fileutils'

# BaseAPI - Base class for all API endpoints
# Provides common functionality: JSON responses, error handling, request validation

class BaseAPI < Sinatra::Base
  # Configure Sinatra to NOT use ShowExceptions (we handle JSON errors ourselves)
  configure do
    disable :show_exceptions  # Don't show HTML error pages
    disable :raise_errors      # Don't raise errors to Rack
  end
  
  # Helper method to safely log to file
  def safe_log(message, level = 'INFO')
    begin
      log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
      FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
      File.open(log_file, 'a') do |f|
        f.puts "[#{Time.now.iso8601}] [#{level}] #{message}"
        f.flush
      end
    rescue => e
      # If file logging fails, write to STDERR as fallback
      begin
        STDERR.puts "[#{Time.now.iso8601}] [#{level}] [FALLBACK] #{message}"
        STDERR.puts "[#{Time.now.iso8601}] [ERROR] [FALLBACK] safe_log failed: #{e.class}: #{e.message}"
        STDERR.flush
      rescue
        # Absolute last resort - do nothing
      end
    end
  end
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
    halt 400, error_response(env['sinatra.error'].message, code: 'VALIDATION_ERROR', status: 400)
  end

  error StandardError do
    begin
      # Log that we're in the error handler
      begin
        log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
        FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
        File.open(log_file, 'a') do |f|
          f.puts "[#{Time.now.iso8601}] [ERROR] =========================================="
          f.puts "[#{Time.now.iso8601}] [ERROR] ENTERING STANDARDERROR HANDLER"
          f.puts "[#{Time.now.iso8601}] [ERROR] env keys: #{env.keys.grep(/sinatra|rack/).inspect}"
          f.puts "[#{Time.now.iso8601}] [ERROR] env['sinatra.error'] exists: #{env.key?('sinatra.error')}"
          f.puts "[#{Time.now.iso8601}] [ERROR] env['sinatra.error'] value: #{env['sinatra.error'].inspect}"
        end
      rescue => log_err
        # Ignore logging errors
      end
      
      error_obj = env['sinatra.error']
      
      # Try to log the error immediately, even if safe_log might fail
      begin
        log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
        FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
        File.open(log_file, 'a') do |f|
          f.puts "[#{Time.now.iso8601}] [ERROR] =========================================="
          f.puts "[#{Time.now.iso8601}] [ERROR] BASEAPI ERROR HANDLER"
          f.puts "[#{Time.now.iso8601}] [ERROR] Error object: #{error_obj.inspect}"
          f.puts "[#{Time.now.iso8601}] [ERROR] Error class: #{error_obj.class if error_obj}"
          f.puts "[#{Time.now.iso8601}] [ERROR] Error message: #{error_obj.message if error_obj && error_obj.respond_to?(:message)}"
          if error_obj && error_obj.backtrace
            f.puts "[#{Time.now.iso8601}] [ERROR] Backtrace:"
            error_obj.backtrace.first(15).each do |line|
              f.puts "[#{Time.now.iso8601}] [ERROR]   #{line}"
            end
          end
          f.puts "[#{Time.now.iso8601}] [ERROR] =========================================="
        end
      rescue => log_err
        # Ignore logging errors
      end
      
      error_msg = if error_obj && error_obj.respond_to?(:message) && !error_obj.message.nil? && !error_obj.message.empty?
        error_obj.message
      else
        error_obj ? "#{error_obj.class}: #{error_obj.inspect}" : 'Unknown error'
      end
      
      # Check if this is a custom error with additional details
      error_code = if error_obj && error_obj.respond_to?(:error_code)
        error_obj.error_code
      else
        'INTERNAL_ERROR'
      end
      
      error_details = {
        error_class: error_obj ? error_obj.class.name : 'Unknown',
        backtrace: error_obj && error_obj.backtrace ? error_obj.backtrace.first(10) : []
      }
      
      # Add custom error details if available
      if error_obj && error_obj.respond_to?(:venice_response_id)
        error_details[:venice_response_id] = error_obj.venice_response_id
        error_details[:available_keys] = error_obj.available_keys if error_obj.respond_to?(:available_keys)
        error_details[:has_content] = error_obj.has_content if error_obj.respond_to?(:has_content)
        error_details[:has_reasoning] = error_obj.has_reasoning if error_obj.respond_to?(:has_reasoning)
        error_details[:log_file] = 'logs/empty_content_error.json'
      end
      
      # Log the error for debugging (using safe_log if available)
      safe_log("=" * 80, 'ERROR')
      safe_log("BASEAPI ERROR HANDLER:", 'ERROR')
      safe_log("Error in #{self.class.name}: #{error_obj.class if error_obj}: #{error_msg}", 'ERROR')
      safe_log(error_obj.backtrace.first(15).join("\n"), 'ERROR') if error_obj && error_obj.backtrace
      safe_log("=" * 80, 'ERROR')
      
      # Use error_response helper which handles serialization safely
      halt 500, error_response(error_msg, code: error_code, details: error_details, status: 500)
    rescue StandardError => e
      # Last resort error handling - try to log this too
      begin
        log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
        FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
        File.open(log_file, 'a') do |f|
          f.puts "[#{Time.now.iso8601}] [ERROR] ERROR HANDLER FAILED: #{e.class}: #{e.message}"
          f.puts "[#{Time.now.iso8601}] [ERROR] Handler backtrace: #{e.backtrace.first(5).join("\n")}"
        end
      rescue
        # Ignore
      end
      
      content_type :json
      status 500
      {
        success: false,
        error: {
          message: "Error handler failed: #{e.message}",
          code: 'INTERNAL_ERROR',
          details: {
            handler_error: e.class.name,
            handler_backtrace: e.backtrace.first(5)
          }
        },
        timestamp: Time.now.iso8601
      }.to_json
    end
  end

  error 404 do
    halt 404, error_response('Resource not found', code: 'NOT_FOUND', status: 404)
  end

  error 500 do
    begin
      error_obj = env['sinatra.error']
      
      # Safely extract error message
      error_msg = begin
        if error_obj && error_obj.respond_to?(:message) && !error_obj.message.nil? && !error_obj.message.to_s.empty?
          error_obj.message.to_s
        elsif error_obj
          "#{error_obj.class}: #{error_obj.inspect[0..500]}"
        else
          'Internal server error'
        end
      rescue => e
        "Error extracting message: #{e.class}: #{e.message}"
      end
      
      # Safely extract error class name
      error_class_name = begin
        if error_obj && error_obj.respond_to?(:class)
          error_obj.class.name
        else
          'Unknown'
        end
      rescue => e
        "Error extracting class: #{e.class}"
      end
      
      # Safely extract backtrace
      error_backtrace = begin
        if error_obj && error_obj.respond_to?(:backtrace) && error_obj.backtrace
          error_obj.backtrace.first(10)
        else
          []
        end
      rescue => e
        []
      end
      
      safe_log("=" * 80, 'ERROR')
      safe_log("ERROR 500 HANDLER:", 'ERROR')
      safe_log("Error: #{error_msg}", 'ERROR')
      safe_log("Class: #{error_class_name}", 'ERROR')
      if error_backtrace.any?
        safe_log("Backtrace:", 'ERROR')
        error_backtrace.each { |line| safe_log("  #{line}", 'ERROR') }
      else
        safe_log("Backtrace: (none available)", 'ERROR')
      end
      safe_log("=" * 80, 'ERROR')
      
      # Use a simple JSON response to avoid recursive errors
      content_type :json
      status 500
      {
        success: false,
        error: {
          message: error_msg,
          code: 'INTERNAL_ERROR',
          details: {
            error_class: error_class_name,
            backtrace: error_backtrace
          }
        },
        timestamp: Time.now.iso8601
      }.to_json
    rescue StandardError => e
      # Last resort - return minimal error
      content_type :json
      status 500
      {
        success: false,
        error: {
          message: "Internal server error: #{e.message}",
          code: 'INTERNAL_ERROR',
          details: {
            handler_error: e.class.name
          }
        },
        timestamp: Time.now.iso8601
      }.to_json
    end
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

