#!/usr/bin/env ruby

# Kill any existing processes on ports 5173 and 5174
puts "Killing existing processes on ports 5173 and 5174..."
[5173, 5174].each do |port|
  pids = `lsof -ti:#{port}`.strip.split("\n")
  pids.each do |pid|
    next if pid.empty?
    system("kill -9 #{pid}") rescue nil
  end
end

# Wait a moment for ports to be released
sleep 1

# Start Vite dev server
puts "Starting Vite dev server..."
vite_pid = spawn("vite", pgroup: true)

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

# Wait for the vite process
Process.wait(vite_pid) rescue nil

