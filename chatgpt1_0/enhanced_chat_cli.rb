#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'io/console'

class ChatGPTCLI
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  VENICE_API_URL = 'https://api.venice.ai/api/v1/chat/completions'

  def initialize
    @openai_api_key = load_openai_api_key
    @venice_api_key = load_venice_api_key
    @conversation = []
    @api_provider = "venice"
    @nesting_level = 0  # Track nesting depth

    if (@openai_api_key.nil? || @openai_api_key.empty?) && (@venice_api_key.nil? || @venice_api_key.empty?)
      puts "Error: No API keys found"
      puts "Create files called 'openAI_api_key' and/or 'venice_api_key' with your keys,"
      puts "or set OPENAI_API_KEY and/or VENICE_API_KEY environment variables"
      exit 1
    end

    if @openai_api_key.nil? || @openai_api_key.empty?
      @api_provider = "venice"
      puts "⚠️  No OpenAI key found, defaulting to Venice.ai"
    elsif @venice_api_key.nil? || @venice_api_key.empty?
      @api_provider = "openai"
      puts "⚠️  No Venice key found, defaulting to OpenAI"
    end

    parse_arguments
  end

  def parse_arguments
    if ARGV.include?('-prompt') || ARGV.include?('--prompt')
      prompt_index = ARGV.find_index { |arg| arg == '-prompt' || arg == '--prompt' }
      if prompt_index && ARGV[prompt_index + 1]
        prompt_name = ARGV[prompt_index + 1]
        load_prompt_by_name(prompt_name)
      else
        puts "❌ -prompt requires a prompt name!"
        puts "Usage: ./chat_cli.rb -prompt [prompt_name]"
        exit 1
      end
    else
      load_default_prompt
    end

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
        opening_line = lines.sample
        puts "\n💬 #{opening_line}"

        @conversation << { role: "user", content: opening_line }

        # Instead of setting a flag, immediately get the response
        puts "\n🎭 Getting Sammy's response..."
        send_opening_message
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

    @conversation << { role: "user", content: selected_line }

    # Get immediate response instead of setting flag
    puts "\n🎭 Getting Sammy's response..."
    puts "🔧 Debug: Using API: #{@api_provider}" if ENV['DEBUG']
    send_opening_message
  end

  def terminal_width
    IO.console&.winsize&.[](1) || 80
  end

  def wrap_text(text, width = terminal_width - 10)
    text.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").strip
  end

  def speak_text(text)
    return unless @voice_enabled

    puts "🔊 Attempting voice output..." if ENV['DEBUG']

    if use_openai_tts(text)
      puts "✅ Used OpenAI TTS" if ENV['DEBUG']
      return
    end

    puts "🔄 Falling back to system voice..." if ENV['DEBUG']

    clean_text = text.encode('UTF-8', invalid: :replace, undef: :replace)
    clean_text = clean_text.gsub(/[^\x00-\x7F]/, ' ').gsub(/\s+/, ' ').strip

    if clean_text.empty?
      puts "❌ Text became empty after cleaning" if ENV['DEBUG']
      return
    end

    escaped_text = clean_text.gsub("'", "'\"'\"'")
    result = system("say -v '#{@voice_name}' '#{escaped_text}'")
    puts "#{result ? '✅' : '❌'} System voice result: #{result}" if ENV['DEBUG']
  end

  def use_openai_tts(text)
    if !@openai_api_key || @openai_api_key.empty?
      puts "❌ No OpenAI key for TTS" if ENV['DEBUG']
      return false
    end

    begin
      clean_text = text.encode('UTF-8', invalid: :replace, undef: :replace).strip
      clean_text = clean_text.gsub(/[^\x00-\x7F]/, ' ').gsub(/\s+/, ' ')

      if clean_text.empty?
        puts "❌ Text became empty after cleaning" if ENV['DEBUG']
        return false
      end

      uri = URI('https://api.openai.com/v1/audio/speech')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@openai_api_key}"
      request['Content-Type'] = 'application/json'

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
        input: clean_text,
        voice: openai_voice,
        response_format: "mp3"
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        audio_file = "/tmp/tts_#{Time.now.to_i}.mp3"
        File.write(audio_file, response.body, mode: 'wb')

        puts "🎵 Saved audio file: #{audio_file}" if ENV['DEBUG']

        play_success = system("afplay '#{audio_file}'")

        if !play_success
          puts "🔄 afplay failed, trying open..." if ENV['DEBUG']
          play_success = system("open '#{audio_file}'")
          sleep(1)
        end

        File.delete(audio_file) if File.exist?(audio_file)

        if play_success
          puts "🎵 Audio played successfully" if ENV['DEBUG']
          return true
        else
          puts "❌ Failed to play audio file" if ENV['DEBUG']
          return false
        end
      else
        puts "❌ OpenAI TTS error: #{response.code} - #{response.body[0..200]}" if ENV['DEBUG']
        return false
      end

    rescue => e
      puts "❌ TTS Error: #{e.message}" if ENV['DEBUG']
      return false
    end
  end

  def find_prompt_index(prompts, selection)
    # Try as number first
    if selection.match?(/^\d+$/)
      index = selection.to_i - 1
      return index if index >= 0 && index < prompts.length
    end
    
    # Try as exact name match
    prompts.each_with_index do |prompt, i|
      return i if prompt[:name].downcase == selection.downcase
    end
    
    # Try as partial name match
    matches = prompts.select.with_index do |prompt, i|
      prompt[:name].downcase.include?(selection.downcase)
    end
    
    return matches.first[1] if matches.length == 1
    
    if matches.length > 1
      puts "🔍 Multiple matches found:"
      matches.each_with_index do |(prompt, original_index), i|
        puts "   #{original_index + 1}. #{prompt[:name]}"
      end
      puts "💡 Be more specific or use the number"
    end
    
    return -1  # Not found
  end

  def show_prompt_menu_help
    puts "\n🎭 Prompt Menu Help"
    puts "=" * 30
    puts "📋 Available Commands:"
    puts "   [number]         - Preview prompt content (e.g. 3)"
    puts "   [name]           - Preview prompt by name (e.g. craig_and_jim)"
    puts "   l[number]        - Load prompt (e.g. l1, l5)"
    puts "   l[name]          - Load prompt by name (e.g. lcraig_and_jim)"
    puts "   q, quit, exit    - Return to main chat"
    puts "   h, ?, help       - Show this help"
    puts ""
    puts "💡 Tips:"
    puts "   - You can use partial names (e.g. 'craig' for 'craig_and_jim')"
    puts "   - Preview first to see what the prompt does"
    puts "   - Loading a prompt changes the AI's personality"
    puts "   - System prompts guide how the AI responds"
    puts "=" * 30
  end

  def interactive_prompt_selection
    @nesting_level += 1
    prompt_dir = "./prompts"

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
    puts "Enter number or name to preview, 'l[number/name]' to load, 'q' to quit"
    puts "Type 'h', '?' or 'help' for more options"

    loop do
      print "\nPrompt menu> "
      input = gets.chomp.downcase

      case input
      when 'q', 'quit', 'exit'
        break
      when 'h', '?', 'help'
        show_prompt_menu_help
      when /^l(.+)$/
        selection = $1.strip
        index = find_prompt_index(prompts, selection)
        if index >= 0
          prompt = prompts[index]
          load_system_prompt(prompt[:content], prompt[:name])
          break
        else
          puts "❌ Invalid selection: '#{selection}'"
          puts "💡 Use number (1-#{prompts.length}) or exact name"
        end
      when /^(.+)$/
        selection = $1.strip
        index = find_prompt_index(prompts, selection)
        if index >= 0
          prompt = prompts[index]
          puts "\n📋 Preview of '#{prompt[:name]}':"
          puts "=" * 40
          puts prompt[:content]
          puts "=" * 40
        else
          puts "❌ Invalid selection: '#{selection}'"
          puts "💡 Use number (1-#{prompts.length}) or exact name"
        end
      else
        puts "Enter a number/name to preview, l[number/name] to load, 'q' to quit, or 'help' for options"
      end
    end
    @nesting_level -= 1
  end

  def load_system_prompt(content, name)
    # Store current API provider before modifying conversation
    current_provider = @api_provider

    # Only clear conversation if it's empty or just has a system prompt
    if @conversation.length <= 1
      @conversation.clear
    else
      # Remove old system prompt but keep the conversation
      @conversation.shift if @conversation.first && @conversation.first[:role] == "system"
    end

    # Add new system prompt at the beginning
    @conversation.unshift({ role: "system", content: content })

    # Restore API provider setting (CRITICAL FIX)
    @api_provider = current_provider

    puts "✨ System prompt '#{name}' loaded!"
    puts "🎭 ChatGPT will now follow this persona/instruction set."
    puts "🌐 Still using #{@api_provider.upcase} API"

    if @voice_enabled
      speak_text("System prompt #{name} loaded! I'm ready to chat with my new personality!")
    end
  end

  def interactive_voice_selection
    @nesting_level += 1
    puts "\n🎭 Voice Selection Menu"
    puts "=" * 40

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

    english_voices = voices.select { |v| v[:lang].include?('en_') }

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
    @nesting_level -= 1
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

  def load_openai_api_key
    key_file = 'openAI_api_key'

    if File.exist?(key_file)
      File.read(key_file).strip
    else
      ENV['OPENAI_API_KEY']
    end
  end

  def load_venice_api_key
    key_file = 'venice_api_key'

    if File.exist?(key_file)
      File.read(key_file).strip
    else
      ENV['VENICE_API_KEY']
    end
  end

  def current_api_key
    case @api_provider
    when 'openai'
      @openai_api_key
    when 'venice'
      @venice_api_key
    else
      @openai_api_key
    end
  end

  def start
    puts "Chat CLI - Type 'exit' to quit, 'clear' to clear conversation"
    puts "Commands: 'voice on/off' to toggle speech, 'listen' for voice input"
    puts "         'voices' to browse and sample voices interactively"
    puts "         'prompts' to load system prompts from ./prompts/*.prompt"
    puts "         'save' to save current chat to ./chats/ directory"
    puts "         'roleplay [number]' to start auto-conversation (e.g. 'roleplay 25')"
    puts "         'api [openai|venice]' to switch API providers"
    puts "         '?' to show menu, '??' to send '?' to AI"
    puts "Usage: ./chat_cli.rb -prompt [prompt_name] -o (for opening line options)"
    puts "-" * 60

    @voice_enabled = false  # Start with voice OFF
    @voice_name = "Daniel"

    puts "🔇 Voice disabled by default (type 'voice on' to enable)"
    puts "🌐 Using #{@api_provider.upcase} API"

    # Debug: Show what happened with API selection
    puts "📊 Debug: Venice key present: #{!(@venice_api_key.nil? || @venice_api_key.empty?)}" if ENV['DEBUG']
    puts "📊 Debug: Selected provider: #{@api_provider}" if ENV['DEBUG']

    show_api_key_status

    loop do
      print "\n> "
      input = gets.chomp

      case input
      when 'exit', 'quit'
        # Offer to save before exiting
        offer_save_on_exit
        puts "Goodbye!"
        break
      when 'clear'
        # Store API provider before clearing
        current_provider = @api_provider
        @conversation.clear
        @api_provider = current_provider  # Restore it
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
      when /^api (openai|venice)$/i
        switch_api_provider($1)
        next
      when 'listen'
        input = listen_for_speech
        next if input.nil? || input.empty?
      when 'keys'
        show_api_key_status
        next
      when 'test-voice'
        test_voice_system
        next
      when '?'
        show_help_menu
        next
      when '??'
        send_message('?')
        next
      when ''
        next
      else
        # Debug: show what input was received
        puts "Debug: Input received: '#{input}'" if ENV['DEBUG']
      end

      send_message(input)
    end
  end

  def offer_save_on_exit
    # Only offer to save if there's actual conversation content
    return if @conversation.empty? || conversation_only_has_system_prompt?

    puts "\n💾 Would you like to save this conversation before exiting? (y/n)"
    print "Save chat? > "
    
    response = gets.chomp.downcase
    
    if response == 'y' || response == 'yes'
      save_chat_dialog
      puts "✅ Conversation saved!"
    elsif response == 'n' || response == 'no'
      puts "📝 Conversation not saved."
    else
      puts "🤷 I'll take that as a no. Conversation not saved."
    end
  end

  def conversation_only_has_system_prompt?
    # Check if conversation only contains system prompts
    @conversation.all? { |msg| msg[:role] == "system" }
  end

  def show_api_key_status
    puts "\n🔑 API Key Status:"

    openai_status = if @openai_api_key && !@openai_api_key.empty?
                      "✅ OpenAI: #{@openai_api_key[0..8]}..."
                    else
                      "❌ OpenAI: Not found"
                    end

    venice_status = if @venice_api_key && !@venice_api_key.empty?
                      "✅ Venice: #{@venice_api_key[0..8]}..."
                    else
                      "❌ Venice: Not found"
                    end

    puts "   #{openai_status}"
    puts "   #{venice_status}"
    puts "   Current: #{@api_provider.upcase}"
  end

  def show_help_menu
    @nesting_level += 1
    puts "\n🎭 Chat CLI Help Menu"
    puts "=" * 40
    puts "📝 Basic Commands:"
    puts "   exit, quit       - Exit the program (offers to save)"
    puts "   clear            - Clear conversation history"
    puts "   ?                - Show this help menu"
    puts "   ??               - Send single '?' to AI"
    puts ""
    puts "🎤 Voice Commands:"
    puts "   voice on/off     - Toggle voice output"
    puts "   voices           - Browse and select voices"
    puts "   listen           - Voice input mode"
    puts "   test-voice       - Test voice system"
    puts ""
    puts "🎭 System Commands:"
    puts "   prompts          - Load system prompts"
    puts "   api openai       - Switch to OpenAI API"
    puts "   api venice       - Switch to Venice.ai API"
    puts "   keys             - Show API key status"
    puts ""
    puts "💾 Save Commands:"
    puts "   save             - Save current chat"
    puts "   roleplay [n]     - Auto-roleplay with n exchanges"
    puts ""
    puts "🚀 Usage Examples:"
    puts "   ./chat_cli.rb -prompt flirty -o"
    puts "   roleplay 10"
    puts "   api venice"
    puts "=" * 40
    
    if @nesting_level >= 4
      puts "\n💡 Press Enter to return to chat..."
      gets
    end
    @nesting_level -= 1
  end

  def test_voice_system
    puts "\n🔊 Testing Voice System..."
    puts "Voice enabled: #{@voice_enabled}"
    puts "Voice name: #{@voice_name}"
    puts "OpenAI key available: #{@openai_api_key && !@openai_api_key.empty?}"

    test_message = "Hello gorgeous! This is a voice test from your fabulous Ruby script!"

    puts "\n1️⃣ Testing System Voice (say command):"
    result = system("say -v '#{@voice_name}' '#{test_message}'")
    puts "System voice result: #{result ? '✅ Success' : '❌ Failed'}"

    if @openai_api_key && !@openai_api_key.empty?
      puts "\n2️⃣ Testing OpenAI TTS:"
      old_debug = ENV['DEBUG']
      ENV['DEBUG'] = '1'

      tts_result = use_openai_tts("Testing OpenAI text to speech, darling!")
      puts "OpenAI TTS result: #{tts_result ? '✅ Success' : '❌ Failed'}"

      ENV['DEBUG'] = old_debug
    else
      puts "\n2️⃣ OpenAI TTS: ❌ No API key available"
    end

    puts "\n🎵 If you heard audio, voice is working! If not, check your audio settings."
  end

  def switch_api_provider(provider)
    case provider.downcase
    when 'openai'
      if @openai_api_key.nil? || @openai_api_key.empty?
        puts "❌ Cannot switch to OpenAI: No API key found!"
        puts "Create a file called 'openAI_api_key' or set OPENAI_API_KEY environment variable"
        return
      end
      @api_provider = 'openai'
      puts "✨ Switched to OpenAI API"
      puts "🎤 Voice: OpenAI TTS available"
    when 'venice'
      if @venice_api_key.nil? || @venice_api_key.empty?
        puts "❌ Cannot switch to Venice: No API key found!"
        puts "Create a file called 'venice_api_key' or set VENICE_API_KEY environment variable"
        return
      end
      @api_provider = 'venice'
      puts "🌟 Switched to Venice.ai API"
      puts "🔓 Using private, uncensored AI models"
      puts "⚠️  Note: Voice generation will use OpenAI TTS (if available) or system voice"
    end

    if @voice_enabled
      speak_text("Switched to #{provider} API")
    end
  end

  def start_roleplay_conversation(exchanges)
    puts "\n🎭 Starting roleplay conversation with #{exchanges} exchanges!"
    puts "📝 Auto-generating conversation between Daddy and Sammy..."
    puts "⏸️  Press Ctrl+C to stop early"
    puts "-" * 50

    # CRITICAL: Store and verify API provider
    puts "🔧 Debug: API provider at roleplay start: #{@api_provider}" if ENV['DEBUG']
    current_provider = @api_provider  # Store it just in case

    # Save current conversation state before roleplay
    conversation_backup = @conversation.dup
    puts "🔧 Debug: Backing up #{conversation_backup.length} messages" if ENV['DEBUG']

    # Add simple roleplay instruction that preserves character
    roleplay_instruction = "Continue as the same character you've been playing and pick up from the last response: Create a roleplay scene with #{exchanges} exchanges. Format as 'DADDY:' and 'SAMMY:' alternating. Start with DADDY."

    @conversation << { role: "user", content: roleplay_instruction }
    puts "🔧 Debug: Added roleplay instruction" if ENV['DEBUG']

    # Verify API provider hasn't changed
    puts "🔧 Debug: API provider before requests: #{@api_provider}" if ENV['DEBUG']

    begin
      exchanges.times do |i|
        puts "\n🔄 Exchange #{i + 1}/#{exchanges}..."

        # Extra debug check each iteration
        puts "🔧 Debug: API provider in loop: #{@api_provider}" if ENV['DEBUG']

        response = make_api_request

        if response['error']
          puts "API Error: #{response['error']['message']}"
          break
        end

        if response['choices'] && response['choices'][0]
          reply = response['choices'][0]['message']['content']
          @conversation << { role: "assistant", content: reply }

          display_roleplay_response(reply)

          sleep(1)

          @conversation << { role: "user", content: "Continue the conversation with the next detailed exchange. Keep responses descriptive and immersive, staying true to the setting." }
        else
          puts "Error generating response"
          break
        end
      end

    rescue Interrupt
      puts "\n\n⏹️  Roleplay stopped by user!"
    ensure
      # Make sure API provider is still correct
      @api_provider = current_provider if @api_provider != current_provider
    end

    puts "\n🎭 Roleplay conversation complete!"
    puts "💾 Type 'save' to save this conversation to file"
    puts "🎤 Type 'play' to hear the full roleplay, or 'save-audio' to save audio file"

    loop do
      print "\nRoleplay menu> "
      choice = gets.chomp.downcase

      case choice
      when 'save'
        save_text_file_only
        break
      when 'play'
        play_full_roleplay
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

  def display_roleplay_response(response)
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
        when "SAMMY"
          puts "\n🐷 SAMMY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
        end
      else
        puts "\n💬 #{line}"
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

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    base_filename = "#{timestamp}_roleplay"
    txt_filepath = File.join(chats_dir, "#{base_filename}.txt")

    save_text_file(txt_filepath)
    puts "💾 Roleplay saved to: #{txt_filepath}"
  end

  def play_full_roleplay
    puts "\n🎤 Playing full roleplay conversation..."

    full_text = create_roleplay_audio_script

    if full_text.empty?
      puts "❌ No content to play"
      return
    end

    chunks = split_text_for_tts(full_text)

    puts "🎵 Playing #{chunks.length} audio segments..."
    puts "⏸️  Press Ctrl+C to cancel playback"

    begin
      chunks.each_with_index do |chunk, i|
        puts "🔊 Playing segment #{i + 1}/#{chunks.length}..."

        if @voice_enabled
          speak_text(chunk)
          sleep(1)
        end
      end

      puts "✅ Roleplay audio complete!"
    rescue Interrupt
      puts "\n🛑 Playback cancelled by user"
    end
  end

  def split_text_for_tts(text, max_length = 3500)
    return [text] if text.length <= max_length

    chunks = []
    current_chunk = ""

    sentences = text.split(/(?<=[.!?])\s+/)

    sentences.each do |sentence|
      if (current_chunk + sentence).length <= max_length
        current_chunk += (current_chunk.empty? ? "" : " ") + sentence
      else
        chunks << current_chunk unless current_chunk.empty?
        current_chunk = sentence
      end
    end

    chunks << current_chunk unless current_chunk.empty?
    chunks
  end

  def save_roleplay_audio
    puts "\n🎵 Generating roleplay audio file..."

    chats_dir = "./chats"
    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    base_filename = "#{timestamp}_roleplay"

    full_text = create_roleplay_audio_script

    if full_text.empty?
      puts "❌ No content to convert to audio"
      return
    end

    chunks = split_text_for_tts(full_text)
    puts "🎵 Generating #{chunks.length} audio segments..."

    audio_files = []

    begin
      chunks.each_with_index do |chunk, i|
        puts "🔊 Generating segment #{i + 1}/#{chunks.length}..."

        segment_file = "/tmp/roleplay_segment_#{i}_#{Time.now.to_i}.mp3"

        if generate_openai_audio_segment(chunk, segment_file)
          audio_files << segment_file
        else
          puts "❌ Failed to generate segment #{i + 1}"
          break
        end
      end

      if audio_files.length == chunks.length
        final_audio_file = File.join(chats_dir, "#{base_filename}.mp3")

        if audio_files.length == 1
          File.rename(audio_files.first, final_audio_file)
        else
          puts "🔗 Combining audio segments..."
          combine_success = system("cat #{audio_files.join(' ')} > '#{final_audio_file}'")

          if combine_success
            puts "✅ Roleplay audio saved to: #{final_audio_file}"
            puts "🎤 Audio file contains the complete roleplay conversation!"
          else
            puts "❌ Failed to combine audio segments"
            puts "💡 Individual segments saved in /tmp/ if you want to combine manually"
          end
        end
      else
        puts "❌ Not all segments generated successfully"
      end

    rescue Interrupt
      puts "\n🛑 Audio generation cancelled by user"
    ensure
      audio_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
    end
  end

  def create_roleplay_audio_script
    audio_script = []

    @conversation.each do |message|
      next if message[:role] == "system"
      next if message[:role] == "user" && message[:content].include?("Continue the conversation")

      case message[:role]
      when "assistant"
        if message[:content].match(/^(DADDY|SAMMY):\s*(.+)$/im)
          audio_script << message[:content]
        else
          audio_script << "ChatGPT says: #{message[:content]}"
        end
      end
    end

    audio_script.join("... ... ... ")
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
        puts "\n🎭 Sammy: #{wrapped_reply}"

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
    return false unless @openai_api_key && !@openai_api_key.empty?

    begin
      uri = URI('https://api.openai.com/v1/audio/speech')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@openai_api_key}"
      request['Content-Type'] = 'application/json'

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

    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    if @conversation.empty?
      puts "❌ No conversation to save!"
      return
    end

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")

    first_user_message = @conversation.find { |msg| msg[:role] == "user" }
    if first_user_message
      preview = first_user_message[:content][0..30].gsub(/[^\w\s-]/, '').gsub(/\s+/, '_')
      base_filename = "#{timestamp}_#{preview}"
    else
      base_filename = "#{timestamp}_chat"
    end

    txt_filepath = File.join(chats_dir, "#{base_filename}.txt")
    save_text_file(txt_filepath)

    puts "💾 Chat saved to: #{txt_filepath}"
    puts "📊 Saved #{@conversation.length} messages"

    if @voice_enabled
      speak_text("Chat conversation saved successfully!")
    end
  end

  def save_text_file(filepath)
    content = []
    content << "Chat CLI Conversation"
    content << "=" * 50
    content << "Date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    content << "Voice: #{@voice_name}"
    content << "API: #{@api_provider.upcase}"
    content << "=" * 50
    content << ""

    line_width = 90

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
        content << "🤖 AI:"
        wrapped_lines = wrap_text_for_file(message[:content], line_width)
        wrapped_lines.each { |line| content << line }
        content << ""
      end
    end

    File.write(filepath, content.join("\n"))
  end

  def wrap_text_for_file(text, width)
    return [text] if text.length <= width

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
        puts "\nAI: #{wrapped_reply}"

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
    puts "🔧 Debug: Making request to #{@api_provider}" if ENV['DEBUG']
    puts "🔧 Debug: API key being used: #{current_api_key[0..8]}..." if ENV['DEBUG'] && current_api_key

    case @api_provider
    when 'openai'
      make_openai_request
    when 'venice'
      make_venice_request
    else
      puts "🔧 Debug: Unknown provider '#{@api_provider}', defaulting to OpenAI" if ENV['DEBUG']
      make_openai_request
    end
  end

  def make_openai_request
    uri = URI(OPENAI_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@openai_api_key}"
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

  def make_venice_request
    uri = URI(VENICE_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@venice_api_key}"
    request['Content-Type'] = 'application/json'

    payload = {
      model: "llama-3.3-70b",
      messages: @conversation,
      max_tokens: 1000,
      temperature: 0.7,
      venice_parameters: {
        include_venice_system_prompt: false,  # Use our custom prompts instead
        top_p: 0.9,
        repetition_penalty: 1.1
      }
    }

    request.body = payload.to_json

    puts "🔧 Debug: Venice request payload: #{payload[:model]}" if ENV['DEBUG']

    response = http.request(request)
    JSON.parse(response.body)
  end
end

if __FILE__ == $0
  ChatGPTCLI.new.start
end