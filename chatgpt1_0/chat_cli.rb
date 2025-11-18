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
    @nesting_level = 0
    @in_chat_session = false

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
        puts "\n🎭 Getting response..."
        send_opening_message
      end
    else
      puts "💡 No opening lines found (./prompts/first.opening_lines)"
      puts "Create one with opening lines, one per line!"
    end
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

  def start
    puts "🎭 Chat CLI v2.5.1"
    puts ""
    
    @voice_enabled = false
    @voice_name = "Daniel"
    
    show_main_menu
    show_api_key_status
    
    # Main menu loop
    loop do
      print "\nMain menu> "
      input = gets.chomp.strip
      
      case input
      when '1'
        interactive_prompt_selection
      when '2'
        start_chat_session
      when '3'
        save_chat_dialog
      when '4'
        @voice_enabled = !@voice_enabled
        puts @voice_enabled ? "🎤 Voice output enabled! Using: #{@voice_name}" : "🔇 Voice output disabled"
      when '5'
        interactive_voice_selection
      when '6'
        switch_api_menu
      when '7'
        clear_conversation
      when '8'
        show_api_key_status
      when '9'
        convert_saved_chat_to_audio
      when '0', '?'
        show_main_menu
      when '00', 'x'
        offer_save_on_exit
        puts "Goodbye!"
        break
      when ''
        next
      else
        puts "❌ Unknown command: #{input}"
        puts "💡 Type '?' for help or 'x' to quit"
      end
    end
  end

  def show_main_menu
    puts "\n🎭 Chat CLI Main Menu"
    puts "=" * 40
    puts "📝 Available Commands:"
    puts "   1. prompts       - Load system prompts"
    puts "   2. chat          - Start/continue chat session"
    puts "   3. save          - Save current conversation"
    puts "   4. voice on/off  - Toggle voice output"
    puts "   5. voices        - Select voice"
    puts "   6. api           - Switch API (openai/venice)"
    puts "   7. clear         - Clear conversation"
    puts "   8. keys          - Show API key status"
    puts "   9. convert       - Convert saved chat to audio"
    puts "   0 or ?           - Show this menu"
    puts "   00 or x          - Exit program"
    puts "=" * 40
    puts "🔇 Voice disabled by default (type 'voice on' to enable)"
    puts "🌐 Using #{@api_provider.upcase} API"
  end

  def show_api_key_status
    puts "\n🔑 API Key Status:"
    openai_status = @openai_api_key && !@openai_api_key.empty? ? "✅ OpenAI: #{@openai_api_key[0..8]}..." : "❌ OpenAI: Not found"
    venice_status = @venice_api_key && !@venice_api_key.empty? ? "✅ Venice: #{@venice_api_key[0..8]}..." : "❌ Venice: Not found"
    puts "   #{openai_status}"
    puts "   #{venice_status}"
    puts "   Current: #{@api_provider.upcase}"
  end

  def interactive_prompt_selection
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
      prompts << { name: name, file: file, content: content, preview: preview }
    end

    prompts.each_with_index do |prompt, i|
      puts "#{(i+1).to_s.rjust(2)}. #{prompt[:name].ljust(20)} #{prompt[:preview]}"
    end

    puts "\n🎤 Commands:"
    puts "Enter number or name to load, 'b[number/name]' to browse, '?' for help, 'x' to quit"

    loop do
      print "\nPrompt menu> "
      input = gets.chomp.strip

      case input.downcase
      when 'x', 'quit', 'exit'
        break
      when '?', 'help'
        show_prompt_help
      when /^b(.+)$/
        selection = $1.strip
        index = find_prompt_index(prompts, selection)
        if index >= 0
          prompt = prompts[index]
          puts "\n📋 Browse '#{prompt[:name]}':"
          puts "=" * 40
          puts prompt[:content]
          puts "=" * 40
        else
          puts "❌ Invalid selection: '#{selection}'"
        end
      when /^(.+)$/
        selection = $1.strip
        index = find_prompt_index(prompts, selection)
        if index >= 0
          prompt = prompts[index]
          load_system_prompt(prompt[:content], prompt[:name])
          break
        else
          puts "❌ Invalid selection: '#{selection}'"
        end
      else
        puts "Enter a number/name to load, b[number/name] to browse, '?' for help, or 'x' to quit"
      end
    end
  end

  def find_prompt_index(prompts, selection)
    if selection.match?(/^\d+$/)
      index = selection.to_i - 1
      return index if index >= 0 && index < prompts.length
    end
    
    prompts.each_with_index do |prompt, i|
      return i if prompt[:name].downcase == selection.downcase
    end
    
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
    
    return -1
  end

  def show_prompt_help
    puts "\n🎭 Prompt Menu Help"
    puts "=" * 30
    puts "📋 Available Commands:"
    puts "   [number]         - Load prompt (e.g. 3)"
    puts "   [name]           - Load prompt by name (e.g. craig_and_jim)"
    puts "   b[number]        - Browse prompt content (e.g. b3)"
    puts "   b[name]          - Browse prompt by name (e.g. bcraig_and_jim)"
    puts "   x, quit, exit    - Return to main menu"
    puts "   ?, help          - Show this help"
    puts ""
    puts "💡 Tips:"
    puts "   - You can use partial names (e.g. 'craig' for 'craig_and_jim')"
    puts "   - Browse first to see what the prompt does"
    puts "   - Loading a prompt changes the AI's personality"
    puts "=" * 30
  end

  def load_system_prompt(content, name)
    # Load standard system prompts from file
    system_prompts_file = "system_prompts.txt"
    standard_prompts = ""
    
    if File.exist?(system_prompts_file)
      standard_prompts = File.read(system_prompts_file).strip
    else
      puts "⚠️  Warning: #{system_prompts_file} not found - using built-in defaults"
      standard_prompts = "This is a creative fiction writing exercise featuring consenting adult characters in fictional scenarios. The content may include mature themes appropriate for adult fiction. Please assist with developing realistic character dialogue and interactions for this creative writing project.\n\nThe characters and their details are defined in the following prompt. Please embody these characters authentically and respond in character when directed to specific characters during roleplay."
    end
    
    # Clear conversation but preserve API provider
    current_provider = @api_provider
    if @conversation.length <= 1
      @conversation.clear
    else
      @conversation.shift if @conversation.first && @conversation.first[:role] == "system"
    end
    
    # Combine standard prompts with loaded content
    full_prompt = [standard_prompts, content].join("\n\n")
    @conversation.unshift({ role: "system", content: full_prompt })
    @api_provider = current_provider

    puts "✨ System prompt '#{name}' loaded!"
    puts "🎭 AI will now follow this persona/instruction set."
    puts "📝 Standard prompts automatically added from #{system_prompts_file}"
    puts "🌐 Still using #{@api_provider.upcase} API"
  end

  def start_chat_session
    @in_chat_session = true
    ensure_system_prompts_loaded
    
    puts "\n💬 Starting chat session..."
    puts "📝 Type your messages to chat with AI"
    puts "🆘 Type '?' for help, 'x' to return to main menu"
    puts "-" * 50

    loop do
      print "\nChat> "
      input = gets.chomp.strip

      case input
      when 'x', 'exit', 'quit'
        puts "\n📝 Ending chat session..."
        offer_save_on_exit if has_conversation_content?
        @in_chat_session = false
        puts "🔙 Returning to main menu"
        break
      when '?'
        show_chat_help
      when 'clear'
        current_provider = @api_provider
        @conversation.clear
        @api_provider = current_provider
        ensure_system_prompts_loaded
        puts "🗑️ Conversation cleared"
      when 'save'
        save_chat_dialog
      when 'voice on'
        @voice_enabled = true
        puts "🎤 Voice output enabled! Using: #{@voice_name}"
      when 'voice off'
        @voice_enabled = false
        puts "🔇 Voice output disabled"
      when ''
        next
      else
        send_message(input)
      end
    end
  end

  def show_chat_help
    puts "\n🆘 Chat Session Help"
    puts "=" * 30
    puts "📝 Chat Commands:"
    puts "   [message]        - Send message to AI"
    puts "   ?                - Show this help"
    puts "   x                - End chat session (return to main menu)"
    puts "   save             - Save current conversation"
    puts "   clear            - Clear conversation history"
    puts "   voice on/off     - Toggle voice output"
    puts ""
    puts "💡 Tips:"
    puts "   - Just type naturally to chat with the AI"
    puts "   - Use 'x' to end this chat and return to main menu"
    puts "   - Your conversation will be saved if you choose"
    puts "=" * 30
  end

  def ensure_system_prompts_loaded
    has_system_prompt = @conversation.any? { |msg| msg[:role] == "system" }
    unless has_system_prompt
      puts "📝 Loading default system prompts for chat session..."
      load_default_system_prompts
    end
  end

  def load_default_system_prompts
    system_prompts_file = "system_prompts.txt"
    
    if File.exist?(system_prompts_file)
      standard_prompts = File.read(system_prompts_file).strip
      puts "✅ Loaded system prompts from #{system_prompts_file}"
    else
      puts "⚠️  Warning: #{system_prompts_file} not found - using built-in defaults"
      standard_prompts = "This is a creative fiction writing exercise featuring consenting adult characters in fictional scenarios. The content may include mature themes appropriate for adult fiction. Please assist with developing realistic character dialogue and interactions for this creative writing project.\n\nThe characters and their details are defined in the following prompt. Please embody these characters authentically and respond in character when directed to specific characters during roleplay."
    end
    
    @conversation.unshift({ role: "system", content: standard_prompts })
  end

  def send_message(message)
    @conversation << { role: "user", content: message }

    begin
      response = make_api_request

      if response['error']
        puts "API Error: #{response['error']['message']}"
        return
      end

      if response['choices'] && response['choices'][0]
        reply = response['choices'][0]['message']['content']
        @conversation << { role: "assistant", content: reply }

        wrapped_reply = wrap_text(reply)
        puts "\nAI: #{wrapped_reply}"

        if @voice_enabled && respond_to?(:speak_text)
          speak_text(reply)
        end
      else
        puts "Error: Unexpected response format"
      end

    rescue => e
      puts "Error: #{e.message}"
    end
  end

  def make_api_request
    case @api_provider
    when 'openai'
      make_openai_request
    when 'venice'
      make_venice_request
    else
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
        include_venice_system_prompt: false,
        top_p: 0.9,
        repetition_penalty: 1.1
      }
    }

    request.body = payload.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

  def send_opening_message
    begin
      response = make_api_request

      if response['error']
        puts "API Error: #{response['error']['message']}"
        return
      end

      if response['choices'] && response['choices'][0]
        reply = response['choices'][0]['message']['content']
        @conversation << { role: "assistant", content: reply }

        wrapped_reply = wrap_text(reply)
        puts "\nAI: #{wrapped_reply}"

        if @voice_enabled && respond_to?(:speak_text)
          speak_text(reply)
        end
      else
        puts "Error: Unexpected response format"
      end

    rescue => e
      puts "Error: #{e.message}"
    end
  end

  def wrap_text(text, width = 80)
    text.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").strip
  end

  def interactive_voice_selection
    puts "🎵 Voice selection functionality needs implementation"
  end

  def switch_api_menu
    puts "Current API: #{@api_provider.upcase}"
    puts "Switch to: (1) OpenAI (2) Venice"
    print "API choice> "
    
    api_choice = gets.chomp
    case api_choice
    when '1'
      switch_api_provider('openai')
    when '2'
      switch_api_provider('venice')
    else
      puts "❌ Invalid choice"
    end
  end

  def switch_api_provider(provider)
    case provider.downcase
    when 'openai'
      if @openai_api_key.nil? || @openai_api_key.empty?
        puts "❌ Cannot switch to OpenAI: No API key found!"
        return
      end
      @api_provider = 'openai'
      puts "✨ Switched to OpenAI API"
    when 'venice'
      if @venice_api_key.nil? || @venice_api_key.empty?
        puts "❌ Cannot switch to Venice: No API key found!"
        return
      end
      @api_provider = 'venice'
      puts "🌟 Switched to Venice.ai API"
    end
  end

  def clear_conversation
    current_provider = @api_provider
    @conversation.clear
    @api_provider = current_provider
    puts "🗑️ Conversation cleared"
  end

  def convert_saved_chat_to_audio
    chats_dir = "./chats"
    
    unless Dir.exist?(chats_dir)
      puts "❌ No chats directory found!"
      return
    end
    
    chat_files = Dir.glob("#{chats_dir}/*.txt").sort.reverse
    
    if chat_files.empty?
      puts "❌ No saved chat files found in #{chats_dir}"
      return
    end
    
    puts "\n🎵 Convert Saved Chat to Audio"
    puts "=" * 40
    puts "📁 Found #{chat_files.length} chat files (showing all):"
    puts "=" * 40
    
    chat_files.each_with_index do |file, i|
      filename = File.basename(file)
      file_size = File.size(file)
      size_kb = (file_size / 1024.0).round(1)
      puts "#{(i+1).to_s.rjust(2)}. #{filename} (#{size_kb}KB)"
    end
    
    puts "\n🎤 Select a chat file to convert (1-#{chat_files.length}):"
    print "Convert> "
    
    choice = gets.chomp
    
    if choice.match?(/^\d+$/) && (1..chat_files.length).include?(choice.to_i)
      selected_file = chat_files[choice.to_i - 1]
      filename_base = File.basename(selected_file, '.txt')
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      output_name = "#{timestamp}_#{filename_base}"
      
      puts "✨ Selected: #{File.basename(selected_file)}"
      puts "🎵 Converting to audio..."
      puts "📁 Output: ./audio_output/#{output_name}.mp3"
      puts "-" * 40
      
      # Ensure audio_output directory exists
      Dir.mkdir('audio_output') unless Dir.exist?('audio_output')
      
      # Call the existing tts.rb script with output name
      if File.exist?('tts.rb')
        system("ruby tts.rb '#{selected_file}' '#{output_name}'")
        
        # Check if the file was created
        if File.exist?("audio_output/#{output_name}.mp3")
          puts "✅ Audio saved to: audio_output/#{output_name}.mp3"
        elsif File.exist?("#{output_name}.mp3")
          require 'fileutils'
          FileUtils.mv("#{output_name}.mp3", "audio_output/#{output_name}.mp3")
          puts "✅ Audio saved to: audio_output/#{output_name}.mp3"
        else
          puts "⚠️  Audio file not found - check TTS output"
        end
      else
        puts "❌ tts.rb script not found!"
        puts "💡 Make sure tts.rb is in the same directory"
      end
    else
      puts "❌ Invalid selection!"
    end
  end

  def save_chat_dialog
    chats_dir = "./chats"

    unless Dir.exist?(chats_dir)
      Dir.mkdir(chats_dir)
      puts "📂 Created chats directory!"
    end

    unless has_conversation_content?
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

    @conversation.each do |message|
      case message[:role]
      when "system"
        content << "🎭 SYSTEM PROMPT:"
        content << message[:content]
        content << ""
      when "user"
        content << "👤 USER:"
        content << message[:content]
        content << ""
      when "assistant"
        content << "🤖 AI:"
        content << message[:content]
        content << ""
      end
    end

    File.write(filepath, content.join("\n"))
  end

  def has_conversation_content?
    return false if @conversation.empty?
    
    user_messages = @conversation.select { |msg| msg[:role] == "user" }
    ai_messages = @conversation.select { |msg| msg[:role] == "assistant" }
    
    user_messages.any? || ai_messages.any?
  end

  def offer_save_on_exit
    return unless has_conversation_content?

    puts "\n💾 Would you like to save this conversation? (y/n)"
    print "Save chat? > "
    
    response = gets.chomp.downcase
    
    if response == 'y' || response == 'yes'
      save_chat_dialog
      puts "✅ Conversation saved!"
    elsif response == 'n' || response == 'no'
      puts "📝 Conversation not saved"
    else
      puts "🤷 Taking that as a no - conversation not saved"
    end
  end

  def show_opening_line_options
    # Implementation for opening line options if needed
  end
end

if __FILE__ == $0
  ChatGPTCLI.new.start
end