#!/usr/bin/env ruby

require 'fileutils'

# Define log directory
LOG_DIR = File.expand_path('../../../logs', __FILE__)
FileUtils.mkdir_p(LOG_DIR) unless File.directory?(LOG_DIR)

BACKEND_LOG = File.join(LOG_DIR, 'backend.log')
FRONTEND_LOG = File.join(LOG_DIR, 'frontend.log')

puts "Development server logs will be written to:"
puts "  Backend: #{BACKEND_LOG}"
puts "  Frontend: #{FRONTEND_LOG}"
puts ""

# Kill any existing processes on ports 4567, 5173, and 5174
puts "Killing existing processes on ports 4567, 5173, and 5174..."
[4567, 5173, 5174].each do |port|
  pids = `lsof -ti:#{port}`.strip.split("\n")
  pids.each do |pid|
    next if pid.empty?
    system("kill -9 #{pid}") rescue nil
  end
end

# Wait a moment for ports to be released
sleep 1

# Start backend server (using Puma directly to avoid Rack's automatic middleware)
puts "Starting backend server (port 4567)..."
# Get project root (go up from frontend/scripts to project root)
script_dir = File.dirname(__FILE__)
project_root = File.expand_path('../..', script_dir)
backend_dir = File.join(project_root, 'backend')
backend_pid = spawn(
  "sh", "-c", "cd '#{backend_dir}' && PORT=4567 bundle exec puma config.ru -p 4567 -e development",
  out: [BACKEND_LOG, 'a'],
  err: [BACKEND_LOG, 'a'],
  pgroup: true
)
Process.detach(backend_pid)

# Wait a moment for backend to start
sleep 3

# Start Vite dev server
puts "Starting Vite dev server..."
vite_pid = spawn(
  "vite",
  out: [FRONTEND_LOG, 'a'],
  err: [FRONTEND_LOG, 'a'],
  pgroup: true
)
Process.detach(vite_pid)

# Wait for server to be ready (poll for port)
def port_in_use?(port)
  `lsof -ti:#{port}`.strip.length > 0
end

puts "Waiting for server to start..."
max_attempts = 30
attempt = 0
port = nil

while attempt < max_attempts
  if port_in_use?(5173)
    port = 5173
    break
  elsif port_in_use?(5174)
    port = 5174
    break
  end
  sleep 0.5
  attempt += 1
end

if port
  sleep 1  # Give server a moment to fully start
  puts "Opening Chrome on http://localhost:#{port}..."
  system('open -a "Google Chrome" "http://localhost:' + port.to_s + '"') rescue puts "Could not open Chrome automatically"
else
  puts "Warning: Could not detect server port"
end

puts ""
puts "=" * 60
puts "Servers running:"
puts "  Backend: http://localhost:4567 (logs: #{BACKEND_LOG})"
puts "  Frontend: http://localhost:#{port} (logs: #{FRONTEND_LOG})"
puts ""
puts "To view logs in real-time, run:"
puts "  tail -f #{BACKEND_LOG}    # Backend logs"
puts "  tail -f #{FRONTEND_LOG}  # Frontend logs"
puts "=" * 60
puts ""

# Wait for processes (Ctrl-C to stop)
begin
  Process.wait(backend_pid) rescue nil
  Process.wait(vite_pid) rescue nil
rescue Interrupt
  puts "\nShutting down servers..."
  [backend_pid, vite_pid].each do |pid|
    Process.kill('TERM', pid) rescue nil
  end
  exit 0
end

