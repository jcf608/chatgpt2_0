# BaseService - Base class for all service objects
# Provides common error handling, validation patterns, and logging

class BaseService
  # Class method for convenient service calls
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  protected

  # Centralized error handling
  def handle_error(error, context = {})
    error_message = build_error_message(error, context)
    log_error(error, context)
    raise StandardError, error_message
  end

  # Build user-friendly error message
  def build_error_message(error, context)
    base_message = error.message || 'An unexpected error occurred'
    
    if context[:operation]
      "#{context[:operation]} failed: #{base_message}"
    else
      base_message
    end
  end

  # Log errors
  def log_error(error, context)
    logger.error("#{self.class.name}: #{error.class} - #{error.message}")
    logger.error("Context: #{context.inspect}") if context.any?
    logger.error(error.backtrace.first(5).join("\n")) if error.backtrace
  end

  # Get logger instance
  def logger
    @logger ||= Logger.new($stdout)
  end

  # Validation helpers
  def validate_presence(value, field_name)
    raise ArgumentError, "#{field_name} is required" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  def validate_not_nil(value, field_name)
    raise ArgumentError, "#{field_name} cannot be nil" if value.nil?
  end
end

