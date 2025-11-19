require_relative 'config/environment'
require_relative 'app'
require 'fileutils'

# Unconditional log write when server starts
begin
  log_file = File.join(File.dirname(__FILE__), '..', 'logs', 'backend.log')
  FileUtils.mkdir_p(File.dirname(log_file)) unless File.directory?(File.dirname(log_file))
  File.open(log_file, 'a') do |f|
    f.puts "=" * 80
    f.puts "[#{Time.now.iso8601}] [INFO] ========================================="
    f.puts "[#{Time.now.iso8601}] [INFO] SERVER STARTED FROM CONFIG.RU"
    f.puts "[#{Time.now.iso8601}] [INFO] Log file path: #{File.expand_path(log_file)}"
    f.puts "[#{Time.now.iso8601}] [INFO] Working directory: #{Dir.pwd}"
    f.puts "[#{Time.now.iso8601}] [INFO] File exists: #{File.exist?(log_file)}"
    f.puts "[#{Time.now.iso8601}] [INFO] File writable: #{File.writable?(File.dirname(log_file))}"
    f.puts "[#{Time.now.iso8601}] [INFO] ========================================="
    f.puts "=" * 80
    f.flush
  end
rescue => e
  STDERR.puts "CRITICAL: Could not write to log file: #{e.class}: #{e.message}"
  STDERR.puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end

# Use our custom JSON error handler at the TOP of the middleware stack
# This catches ALL exceptions and returns JSON instead of HTML
# It runs BEFORE Rack's default middleware, so we always get JSON errors
require_relative 'middleware/json_error_handler'
use JsonErrorHandler

run App

