#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'io/console'

class ChatGPTCLI
  API_URL = 'https://api.openai.com/v1/chat/completions'

  def initialize
    @api_key = load_api_key
    @conversation = []

    if @api_key.nil? || @api_key.empty?
      puts "Error: API key not found"
      puts "Create a file called 'openAI_api_key' with your key, or set OPENAI_API_KEY environment variable"
      exit 1
    end

    # Parse command line arguments
    parse_arguments
  end

  def parse_arguments
    if ARGV.include?('-prompt') || ARGV.include?('--prompt')
      # Find the prompt argument
      prompt_index = ARGV.find_index { |arg| arg == '-prompt' || arg == '--prompt' }
      if prompt_index && ARGV[prompt_index + 1]
        prompt_name = ARGV[prompt_index + 1]
        load_prompt_by_name(prompt_name)
      else
        puts "❌ -prompt requires a prompt name!"
        puts "Usage: ./chatGPT_cli.rb -prompt [prompt_name]"
        exit 1
      end
    else
      # Load default prompt (first.prompt)
      load_default_prompt
    end

    # Handle opening lines
    if ARGV.include?('-o') || ARGV.include?('--opening')
      show_opening_line_options
    else
      load_default_opening_line
    end
  end

  def load_prompt_by_name(prompt_name)
    prompt_file = "./prompts/#{prompt_name}.prompt"

    if File.exist?(prompt_file)
      content = File.read(prompt_file).strip
      @conversation << { role: "system", content: content }
      puts "🎭 Loaded prompt: #{prompt_name}"
    else
      puts "❌ Prompt file not found: #{prompt_file}"
      puts "Available prompts:"
      list_available_prompts
      exit 1
    end
  end

  def load_default_prompt
    default_prompt = "./prompts/first.prompt"

    if File.exist?(default_prompt)
      content = File.read(default_prompt).strip
      @conversation << { role: "system", content: content }
      puts "🎭 Auto-loaded default prompt: first"
    else
      puts "💡 No default prompt found (./prompts/first.prompt)"
      puts "Create one or use -prompt [name] to specify a different prompt"
    end
  end

  def list_available_prompts
    prompt_files = Dir.glob("./prompts/*.prompt")
    if prompt_files.empty?
      puts "  (No .prompt files found in ./prompts/)"
    else
      prompt_files.each do |file|
        name = File.basename(file, '.prompt')
        puts "  #{name}"
      end
    end
  end

  def load_default_opening_line
    opening_file = "./prompts/first.opening_lines"

    if File.exist?(opening_file)
      lines = File.readlines(opening_file).map(&:strip).reject(&:empty?)
      if lines.any?
        # Pick a random opening line
        opening_line = lines.sample
        puts "\n💬 #{opening_line}"

        # Actually send the opening line to ChatGPT!
        @conversation << { role: "user", content: opening_line }

        if @voice_enabled
          speak_text(opening_line)
        end

        # Mark that we need to get the response after showing commands
        @pending_opening_response = true
      end
    else
      puts "💡 No opening lines found (./prompts/first.opening_lines)"
      puts "Create one with opening lines, one per line!"
    end
  end

  def show_opening_line_options
    opening_dir = "./prompts"
    opening_files = Dir.glob("#{opening_dir}/*.opening_lines").sort

    if opening_files.empty?
      puts "❌ No .opening_lines files found in ./prompts/"
      puts "Create some like: ./prompts/flirty.opening_lines"
      exit 1
    end

    puts "\n🎭 Available Opening Line Collections:"
    puts "=" * 60

    collections = []
    opening_files.each do |file|
      name = File.basename(file, '.opening_lines')
      lines = File.readlines(file).map(&:strip).reject(&:empty?)

      if lines.any?
        # Show first line as preview
        preview = lines.first[0..79]
        preview += "..." if lines.first.length > 79

        collections << {
          name: name,
          file: file,
          lines: lines,
          preview: preview,
          count: lines.length
        }
      end
    end

    collections.each_with_index do |collection, i|
      puts "#{(i+1).to_s.rjust(2)}. #{collection[:name].ljust(25)} (#{collection[:count]} lines)"
      puts "    #{collection[:preview]}"
      puts ""
    end

    puts "🎤 Select a collection (1-#{collections.length}):"
    print "> "

    # Clear ARGV to prevent it from interfering with gets
    ARGV.clear
    choice = gets.chomp

    if choice.match?(/^\d+$/) && (1..collections.length).include?(choice.to_i)
      selected_collection = collections[choice.to_i - 1]
      show_lines_from_collection(selected_collection)
    else
      puts "❌ Invalid selection! Exiting..."
      exit 1
    end
  end

  def show_lines_from_collection(collection)
    puts "\n🎭 Opening Lines from '#{collection[:name]}':"
    puts "=" * 60

    collection[:lines].each_with_index do |line, i|
      preview = line[0..79]
      preview += "..." if line.length > 79
      puts "#{(i+1).to_s.rjust(2)}. #{preview}"
    end

    puts "\n🎤 Select an opening line (1-#{collection[:lines].length}) or press Enter for random:"
    print "> "

    choice = gets.chomp

    if choice.empty?
      # Random selection
      selected_line = collection[:lines].sample
      puts "🎲 Random selection: #{selected_line[0..79]}#{'...' if selected_line.length > 79}"
    elsif choice.match?(/^\d+$/) && (1..collection[:lines].length).include?(choice.to_i)
      selected_line = collection[:lines][choice.to_i - 1]
      puts "✨ Selected: #{selected_line[0..79]}#{'...' if selected_line.length > 79}"
    else
      puts "❌ Invalid selection! Using random..."
      selected_line = collection[:lines].sample
    end

    puts "\n💬 #{selected_line}"

    # Actually send the opening line to ChatGPT!
    @conversation << { role: "user", content: selected_line }

    if @voice_enabled
      speak_text(selected_line)
    end

    # Mark that we need to get the response after showing commands
    @pending_opening_response = true
  end

  def terminal_width
    IO.console&.winsize&.[](1) || 80
  end

  def wrap_text(text, width = terminal_width - 10)
    text.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").strip
  end

  def speak_text(text)
    # Try OpenAI TTS first (best quality), fall back to system voices
    if use_openai_tts(text)
      return
    end

    # Fallback to system voice
    escaped_text = text.gsub("'", "'\"'\"'")
    system("say -v '#{@voice_name}' '#{escaped_text}' &")
  end

  def use_openai_tts(text)
    return false unless @api_key && !@api_key.empty?

    begin
      uri = URI('https://api.openai.com/v1/audio/speech')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'

      # Use OpenAI's natural voices
      voice_map = {
        'Samantha' => 'nova',   # Female, young
        'Alex' => 'onyx',       # Male, deep
        'Victoria' => 'shimmer', # Female, elegant
        'Daniel' => 'echo',     # Male, clear
        'Fiona' => 'alloy',     # Female, warm
        'Karen' => 'fable'      # Female, expressive
      }

      openai_voice = voice_map[@voice_name] || 'nova'

      payload = {
        model: "tts-1",
        input: text,
        voice: openai_voice,
        response_format: "mp3"
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        # Save audio and play it
        audio_file = "/tmp/tts_#{Time.now.to_i}.mp3"
        File.write(audio_file, response.body, mode: 'wb')

        # Play with afplay (built into macOS)
        system("afplay '#{audio_file}' && rm '#{audio_file}' &")
        return true
      end

    rescue => e
      puts "TTS Error: #{e.message}" if ENV['DEBUG']
    end

    false
  end

  def interactive_prompt_selection
    prompt_dir = "./prompts"  # Look in current directory, not root!

    unless Dir.exist?(prompt_dir)
      puts "❌ Prompt directory './prompts' not found!"
      puts "Create it with: mkdir -p prompts"
      return
    end

    prompt_files = Dir.glob("#{prompt_dir}/*.prompt").sort

    if prompt_files.empty?
      puts "📂 No .prompt files found in ./prompts/"
      puts "Create some prompt files like: ./prompts/creative.prompt"
      return
    end

    puts "\n🎭 System Prompt Selection"
    puts "=" * 40

    prompts = []
    prompt_files.each do |file|
      name = File.basename(file, '.prompt')
      content = File.read(file).strip
      preview = content.length > 100 ? content[0..97] + "..." : content

      prompts << {
        name: name,
        file: file,
        content: content,
        preview: preview
      }
    end

    prompts.each_with_index do |prompt, i|
      puts "#{(i+1).to_s.rjust(2)}. #{prompt[:name].ljust(20)} #{prompt[:preview]}"
    end

    puts "\n🎤 Commands:"
    puts "Enter number to preview, 'l[number]' to load, 'q' to quit"

    loop do
      print "\nPrompt menu> "
      input = gets.chomp.downcase

      case input
      when 'q', 'quit', 'exit'
        break
      when /^l(\d+)$/
        index = $1.to_i - 1
        if index >= 0 && index < prompts.length
          prompt = prompts[index]
          load_system_prompt(prompt[:content], prompt[:name])
          break
        else
          puts "Invalid selection!"
        end
      when /^\d+$/
        index = input.to_i - 1
        if index >= 0 && index < prompts.length
          prompt = prompts[index]
          puts "\n📋 Preview of '#{prompt[:name]}':"
          puts "=" * 40
          puts prompt[:content]
          puts "=" * 40
        else
          puts "Invalid number!"
        end
      else
        puts "Enter a number to preview, l[number] to load, or 'q' to quit"
      end
    end
  end

  def load_system_prompt(content, name)
    # Clear conversation and set system prompt
    @conversation.clear
    @conversation << { role: "system", content: content }

    puts "✨ System prompt '#{name}' loaded!"
    puts "🎭 ChatGPT will now follow this persona/instruction set."

    if @voice_enabled
      speak_text("System prompt #{name} loaded! I'm ready to chat with my new personality!")
    end
  end

  def interactive_voice_selection
    puts "\n🎭 Voice Selection Menu"
    puts "=" * 40

    # Get and parse voices
    voices = []
    `say -v '?'`.split("\n").each do |voice_line|
      if voice_line.match(/^(\w+)\s+(.+?)\s+#(.*)$/)
        voices << {
          name: $1,
          lang: $2.strip,
          description: $3.strip
        }
      end
    end

    # Filter to just English voices for simplicity
    english_voices = voices.select { |v| v[:lang].include?('en_') }

    # Show popular choices first
    popular = %w[Samantha Alex Victoria Daniel Fiona Karen]
    popular_voices = english_voices.select { |v| popular.include?(v[:name]) }
    other_voices = english_voices.reject { |v| popular.include?(v[:name]) }

    puts "\n💅 Popular Voices:"
    popular_voices.each_with_index do |voice, i|
      current = (voice[:name] == @voice_name) ? " ← CURRENT" : ""
      puts "#{(i+1).to_s.rjust(2)}. #{voice[:name].ljust(12)} #{voice[:description]}#{current}"
    end

    puts "\n📋 All English Voices:"
    other_voices.each_with_index do |voice, i|
      current = (voice[:name] == @voice_name) ? " ← CURRENT" : ""
      puts "#{(i+1+popular_voices.length).to_s.rjust(2)}. #{voice[:name].ljust(12)} #{voice[:description]}#{current}"
    end

    all_voices = popular_voices + other_voices

    puts "\n🎤 Commands:"
    puts "Enter number to sample voice, 's[number]' to select, 'q' to quit"

    loop do
      print "\nVoice menu> "
      input = gets.chomp.downcase

      case input
      when 'q', 'quit', 'exit'
        break
      when /^s(\d+)$/
        index = $1.to_i - 1
        if index >= 0 && index < all_voices.length
          voice = all_voices[index]
          @voice_name = voice[:name]
          puts "✨ Voice selected: #{voice[:name]}"
          speak_text("Hello gorgeous! I'm #{voice[:name]}, your new voice!")
          break
        else
          puts "Invalid selection!"
        end
      when /^\d+$/
        index = input.to_i - 1
        if index >= 0 && index < all_voices.length
          voice = all_voices[index]
          puts "🎵 Sampling #{voice[:name]}..."
          system("say -v '#{voice[:name]}' 'Hello darling! This is #{voice[:name]} speaking. How do I sound to you, gorgeous?'")
        else
          puts "Invalid number!"
        end
      else
        puts "Enter a number to sample, s[number] to select, or 'q' to quit"
      end
    end
  end

  def listen_for_speech
    puts "Listening... (speak now, press Enter when done)"
    print "> "

    temp_file = "/tmp/speech_input_#{Time.now.to_i}.wav"

    puts "Recording... Press Ctrl+C to stop"
    system("rec -q #{temp_file} silence 1 0.5 3% 1 2.0 3%")

    if File.exist?(temp_file)
      result = `whisper --model tiny --output_format txt --output_dir /tmp #{temp_file} 2>/dev/null`
      text_file = temp_file.gsub('.wav', '.txt')

      if File.exist?(text_file)
        transcribed = File.read(text_file).strip
        File.delete(temp_file) if File.exist?(temp_file)
        File.delete(text_file) if File.exist?(text_file)

        puts "You said: #{transcribed}"
        return transcribed
      end
    end

    puts "Sorry, couldn't understand that!"
    nil
  rescue Interrupt
    puts "\nRecording stopped."
    File.delete(temp_file) if File.exist?(temp_file)
    nil
  end

  def load_api_key
    key_file = 'openAI_api_key'

    if File.exist?(key_file)
      File.read(key_file).strip
    else
      ENV['OPENAI_API_KEY']
    end
  end

  def start
    puts "ChatGPT CLI - Type 'exit' to quit, 'clear' to clear conversation"
    puts "Commands: 'voice on/off' to toggle speech, 'listen' for voice input"
    puts "         'voices' to browse and sample voices interactively"
    puts "         'prompts' to load system prompts from ./prompts/*.prompt"
    puts "         'save' to save current chat to ./chats/ directory"
    puts "         'roleplay [number]' to start auto-conversation (e.g. 'roleplay 25')"
    puts "Usage: ./chatGPT_cli.rb -prompt [prompt_name] -o (for opening line options)"
    puts "-" * 60

    @voice_enabled = true  # Voice ON by default!
    @voice_name = "Daniel"  # Default to Daniel
    @pending_opening_response = false  # Track if we need to get opening response

    puts "🎤 Voice enabled by default using: #{@voice_name}"

    # Check if we have a pending opening response to get
    if @pending_opening_response
      puts "\n🎭 Getting Sammy's response..."
      send_opening_message
      @pending_opening_response = false
    end

    loop do
      print "\n> "
      input = gets.chomp

      case input.downcase
      when 'exit', 'quit'
        puts "Goodbye!"
        break
      when 'clear'
        @conversation.clear
        puts "Conversation cleared."
        next
      when 'voice on'
        @voice_enabled = true
        puts "Voice output enabled! 🎤 Using: #{@voice_name}"
        next
      when 'voice off'
        @voice_enabled = false
        puts "Voice output disabled."
        next
      when 'voices'
        interactive_voice_selection
        next
      when 'prompts'
        interactive_prompt_selection
        next
      when 'save'
        save_chat_dialog
        next
      when /^roleplay (\d+)$/
        exchanges = $1.to_i
        start_roleplay_conversation(exchanges)
        next
      when 'listen'
        input = listen_for_speech
        next if input.nil? || input.empty?
      when ''
        next
      end

      send_message(input)
    end
  end

  def start_roleplay_conversation(exchanges)
    puts "\n🎭 Starting roleplay conversation with #{exchanges} exchanges!"
    puts "📝 Daddy and Sammy will chat automatically..."
    puts "⏸️  Press Ctrl+C to stop early"
    puts "-" * 50

    # Set up the roleplay system prompt with longer response instructions
    roleplay_prompt = "You are alternating between two characters in a conversation:\n\n" +
                      "**DADDY**: A dominant, caring feeder who loves making Sammy bigger. Speaks confidently, uses terms of endearment, and focuses on feeding and growth. Describes actions, settings, and sensations in detail.\n\n" +
                      "**SAMMY**: A flamboyant, witty, and playfully cheeky feedee who adores getting fatter for Daddy. Gay, sassy, flirtatious, with a love for dramatic descriptions and corny humor. Always references weight gain, food, and expanding body in creative ways - loves describing his moobs, belly, fat pad, butt and butt topper. Speaks in first person directly to Daddy with adoring, eager-to-please energy. Expresses desire to grow bigger and indulge more. Proud of size and always wanting more.\n\n" +
                      "Rules:\n" +
                      "- Start each response with either 'DADDY:' or 'SAMMY:'\n" +
                      "- Alternate between characters with each response\n" +
                      "- Each response should be 3-6 sentences long with rich detail\n" +
                      "- Include physical descriptions, emotions, and sensory details\n" +
                      "- SAMMY: Use descriptive language about body changes, eating sensations, and relationship with Daddy\n" +
                      "- DADDY: Focus on feeding, care, and appreciation of Sammy's growth\n" +
                      "- Make responses immersive and engaging with vivid imagery\n" +
                      "- Stay in character for each personality\n" +
                      "- Build on the previous exchange to create a flowing narrative\n\n" +
                      "Start the conversation with DADDY speaking first."

    # Clear conversation and set roleplay prompt
    @conversation.clear
    @conversation << { role: "system", content: roleplay_prompt }

    # Send initial message to start the roleplay
    @conversation << { role: "user", content: "Start a detailed, descriptive conversation between Daddy and Sammy. Generate #{exchanges} total exchanges with rich, immersive dialogue that builds a flowing narrative. Each response should be 3-6 sentences with vivid details." }

    begin
      exchanges.times do |i|
        puts "\n🔄 Exchange #{i + 1}/#{exchanges}..."

        response = make_api_request

        if response['error']
          puts "API Error: #{response['error']['message']}"
          break
        end

        if response['choices'] && response['choices'][0]
          reply = response['choices'][0]['message']['content']
          @conversation << { role: "assistant", content: reply }

          # Parse and display the character responses
          display_roleplay_response(reply)

          # Brief pause between exchanges
          sleep(1)

          # Continue the conversation with emphasis on detail
          @conversation << { role: "user", content: "Continue the conversation with the next detailed exchange. Keep responses descriptive and immersive." }
        else
          puts "Error generating response"
          break
        end
      end

    rescue Interrupt
      puts "\n\n⏹️  Roleplay stopped early!"
    end

    puts "\n🎭 Roleplay conversation complete!"
    puts "💾 Type 'save' to save this conversation to file"
    puts "🎤 Type 'play' to hear the full roleplay, or 'save-audio' to save audio file"

    # Wait for user choice - stay in this loop until they choose
    loop do
      print "\nRoleplay menu> "
      choice = gets.chomp.downcase

      case choice
      when 'save'
        save_text_file_only
        break
      when 'play'
        play_full_roleplay
        # Don't break - let them choose again
      when 'save-audio'
        save_roleplay_audio
        break
      when 'exit', 'quit', ''
        puts "Returning to main menu..."
        break
      else
        puts "Options: 'save' (text only), 'play' (hear it), 'save-audio' (save mp3), or 'exit'"
      end
    end
  end

  def save_text_file_only
    chats_dir = "./chats"

    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    if @conversation.empty?
      puts "❌ No conversation to save!"
      return
    end

    # Generate filename with timestamp
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    base_filename = "#{timestamp}_roleplay"
    txt_filepath = File.join(chats_dir, "#{base_filename}.txt")

    save_text_file(txt_filepath)
    puts "💾 Roleplay saved to: #{txt_filepath}"
  end

  def play_full_roleplay
    puts "\n🎤 Playing full roleplay conversation..."

    # Create the full conversation text
    full_text = create_roleplay_audio_script

    if @voice_enabled && !full_text.empty?
      speak_text(full_text)
    else
      puts "❌ No content to play or voice disabled"
    end
  end

  def save_roleplay_audio
    puts "\n🎵 Generating roleplay audio file..."

    chats_dir = "./chats"
    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    # Generate filename with timestamp
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    base_filename = "#{timestamp}_roleplay"
    audio_filepath = File.join(chats_dir, "#{base_filename}.mp3")

    # Create the full conversation text
    full_text = create_roleplay_audio_script

    if full_text.empty?
      puts "❌ No content to convert to audio"
      return
    end

    # Generate audio using OpenAI TTS
    if generate_openai_audio_segment(full_text, audio_filepath)
      puts "✅ Roleplay audio saved to: #{audio_filepath}"
      puts "🎤 Audio file contains the complete roleplay conversation!"
    else
      puts "❌ Failed to generate audio file"
    end
  end

  def create_roleplay_audio_script
    audio_script = []

    @conversation.each do |message|
      next if message[:role] == "system"  # Skip system prompts
      next if message[:role] == "user" && message[:content].include?("Continue the conversation")  # Skip continuation prompts

      case message[:role]
      when "assistant"
        # Handle roleplay format
        if message[:content].match(/^(DADDY|SAMMY):\s*(.+)$/im)
          audio_script << message[:content]
        else
          audio_script << "ChatGPT says: #{message[:content]}"
        end
      end
    end

    # Join with natural pauses
    audio_script.join("... ... ... ")
  end

  def display_roleplay_response(response)
    # Split response by character labels and display nicely
    lines = response.split(/\n+/)

    lines.each do |line|
      line = line.strip
      next if line.empty?

      if line.match(/^(DADDY|SAMMY):\s*(.+)$/i)
        character = $1.upcase
        dialogue = $2

        case character
        when "DADDY"
          puts "\n👨 DADDY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
          # No voice during roleplay - just display
        when "SAMMY"
          puts "\n🐷 SAMMY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
          # No voice during roleplay - just display
        end
      else
        # Handle responses that don't follow the format
        puts "\n💬 #{line}"
        # No voice during roleplay - just display
      end
    end
  end

  def send_opening_message
    begin
      response = make_api_request

      if response['error']
        puts "API Error: #{response['error']['message']}"
        puts "Error Type: #{response['error']['type']}" if response['error']['type']
        return
      end

      if response['choices'] && response['choices'][0]
        reply = response['choices'][0]['message']['content']
        @conversation << { role: "assistant", content: reply }

        wrapped_reply = wrap_text(reply)
        puts "\nSammy: #{wrapped_reply}"

        speak_text(reply) if @voice_enabled
      else
        puts "Error: Unexpected response format"
        puts "Full response: #{response.inspect}"
      end

    rescue => e
      puts "Error: #{e.message}"
    end
  end

  def generate_openai_audio_segment(text, output_file)
    return false unless @api_key && !@api_key.empty?

    begin
      uri = URI('https://api.openai.com/v1/audio/speech')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'

      # Use OpenAI's natural voices
      voice_map = {
        'Samantha' => 'nova',
        'Alex' => 'onyx',
        'Victoria' => 'shimmer',
        'Daniel' => 'echo',
        'Fiona' => 'alloy',
        'Karen' => 'fable'
      }

      openai_voice = voice_map[@voice_name] || 'nova'

      payload = {
        model: "tts-1",
        input: text,
        voice: openai_voice,
        response_format: "mp3"
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        File.write(output_file, response.body, mode: 'wb')
        return true
      else
        puts "TTS API error: #{response.code}" if ENV['DEBUG']
        return false
      end

    rescue => e
      puts "TTS generation error: #{e.message}" if ENV['DEBUG']
      return false
    end
  end

  private

  def save_chat_dialog
    chats_dir = "./chats"

    # Create chats directory if it doesn't exist
    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    if @conversation.empty?
      puts "❌ No conversation to save!"
      return
    end

    # Generate filename with timestamp
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")

    # Get first user message for filename (sanitized)
    first_user_message = @conversation.find { |msg| msg[:role] == "user" }
    if first_user_message
      preview = first_user_message[:content][0..30].gsub(/[^\w\s-]/, '').gsub(/\s+/, '_')
      base_filename = "#{timestamp}_#{preview}"
    else
      base_filename = "#{timestamp}_chat"
    end

    # Save text file
    txt_filepath = File.join(chats_dir, "#{base_filename}.txt")
    save_text_file(txt_filepath)

    puts "💾 Chat saved to: #{txt_filepath}"
    puts "📊 Saved #{@conversation.length} messages"

    if @voice_enabled
      speak_text("Chat conversation saved successfully!")
    end
  end

  def save_text_file(filepath)
    # Format the conversation nicely with proper line wrapping
    content = []
    content << "ChatGPT CLI Conversation"
    content << "=" * 50
    content << "Date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    content << "Voice: #{@voice_name}"
    content << "=" * 50
    content << ""

    # Set line width to match your example - let's be more precise!
    line_width = 90  # Slightly shorter to ensure proper wrapping

    @conversation.each do |message|
      case message[:role]
      when "system"
        content << "🎭 SYSTEM PROMPT:"
        wrapped_lines = wrap_text_for_file(message[:content], line_width)
        wrapped_lines.each { |line| content << line }
        content << ""
      when "user"
        content << "👤 USER:"
        wrapped_lines = wrap_text_for_file(message[:content], line_width)
        wrapped_lines.each { |line| content << line }
        content << ""
      when "assistant"
        content << "🤖 CHATGPT:"
        wrapped_lines = wrap_text_for_file(message[:content], line_width)
        wrapped_lines.each { |line| content << line }
        content << ""
      end
    end

    # Write to file
    File.write(filepath, content.join("\n"))
  end

  def wrap_text_for_file(text, width)
    # Debug: let's see what's happening
    return [text] if text.length <= width

    # Split text into lines that fit within the specified width
    words = text.split(/\s+/)
    lines = []
    current_line = ""

    words.each do |word|
      if current_line.empty?
        current_line = word
      elsif (current_line + " " + word).length <= width
        current_line += " " + word
      else
        lines << current_line
        current_line = word
      end
    end

    lines << current_line unless current_line.empty?

    # Return array of wrapped lines
    lines
  end

  def send_message(message)
    @conversation << { role: "user", content: message }

    begin
      response = make_api_request

      if response['error']
        puts "API Error: #{response['error']['message']}"
        puts "Error Type: #{response['error']['type']}" if response['error']['type']
        return
      end

      if response['choices'] && response['choices'][0]
        reply = response['choices'][0]['message']['content']
        @conversation << { role: "assistant", content: reply }

        wrapped_reply = wrap_text(reply)
        puts "\nChatGPT: #{wrapped_reply}"

        speak_text(reply) if @voice_enabled
      else
        puts "Error: Unexpected response format"
        puts "Full response: #{response.inspect}"
      end

    rescue => e
      puts "Error: #{e.message}"
    end
  end

  def make_api_request
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'

    payload = {
      model: "gpt-3.5-turbo",
      messages: @conversation,
      max_tokens: 1000,
      temperature: 0.7
    }

    request.body = payload.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end
end

if __FILE__ == $0
  ChatGPTCLI.new.start
end