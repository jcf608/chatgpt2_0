# JsonErrorHandler - Middleware to catch all exceptions and return JSON errors
# This runs BEFORE Rack::ShowExceptions, ensuring we return JSON instead of HTML

class JsonErrorHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue StandardError => e
    # Log the error
    log_error(e, env)
    
    # Return JSON error response
    error_response = {
      success: false,
      error: {
        message: e.message,
        code: error_code_for_exception(e),
        details: {
          error_class: e.class.name,
          backtrace: e.backtrace&.first(10) || []
        }
      },
      timestamp: Time.now.iso8601
    }.to_json

    [
      500,
      {
        'Content-Type' => 'application/json',
        'Content-Length' => error_response.bytesize.to_s
      },
      [error_response]
    ]
  end

  private

  def log_error(error, env)
    begin
      log_file = File.join(File.dirname(__FILE__), '..', '..', 'logs', 'backend.log')
      require 'fileutils'
      FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
      File.open(log_file, 'a') do |f|
        f.puts "=" * 80
        f.puts "[#{Time.now.iso8601}] [ERROR] JSON_ERROR_HANDLER CAUGHT EXCEPTION"
        f.puts "[#{Time.now.iso8601}] [ERROR] #{error.class}: #{error.message}"
        f.puts "[#{Time.now.iso8601}] [ERROR] Request: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
        if error.backtrace
          f.puts "[#{Time.now.iso8601}] [ERROR] Backtrace:"
          error.backtrace.first(15).each do |line|
            f.puts "[#{Time.now.iso8601}] [ERROR]   #{line}"
          end
        end
        f.puts "=" * 80
        f.flush
      end
    rescue => log_err
      # If logging fails, write to STDERR
      STDERR.puts "[#{Time.now.iso8601}] [ERROR] JsonErrorHandler: #{error.class}: #{error.message}"
      STDERR.puts "[#{Time.now.iso8601}] [ERROR] Failed to log to file: #{log_err.message}"
    end
  end

  def error_code_for_exception(error)
    # Check for custom error codes
    return error.error_code if error.respond_to?(:error_code)
    
    # Default codes based on exception class
    case error.class.name
    when /ArgumentError/ then 'VALIDATION_ERROR'
    when /NotFound/ then 'NOT_FOUND'
    else 'INTERNAL_ERROR'
    end
  end
end


