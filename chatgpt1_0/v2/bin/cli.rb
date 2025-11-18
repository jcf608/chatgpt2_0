#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'io/console'

class ChatGPTCLI
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  VENICE_API_URL = 'https://api.venice.ai/api/v1/chat/completions'
  VERSION = "v2.6.0"

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
      puts "⚠️ No OpenAI key found, defaulting to Venice.ai"
    elsif @venice_api_key.nil? || @venice_api_key.empty?
      @api_provider = "openai"
      puts "⚠️ No Venice key found, defaulting to OpenAI"
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
    puts "🎭 Chat CLI #{VERSION}"
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
        puts "\n📋 Returning to main menu..."
      when '2'
        continue_conversation
      when '3'
        start_chat_session
      when '4'
        save_chat_dialog
      when '5'
        @voice_enabled = !@voice_enabled
        puts @voice_enabled ? "🎤 Voice output enabled! Using: #{@voice_name}" : "🔇 Voice output disabled"
      when '6'
        interactive_voice_selection
      when '7'
        switch_api_menu
      when '8'
        clear_conversation
      when '9'
        show_api_key_status
      when '10'
        convert_saved_chat_to_audio
      when '11'
        start_extended_dialogue
      when '0', '?'
        show_main_menu
        next  # Skip the show_main_menu at the end since we just called it
      when '00', 'x'
        offer_save_on_exit
        puts "Goodbye! 👋✨"
        break
      when ''
        # Just redisplay menu for empty input
        show_main_menu
        next  # Skip the show_main_menu at the end since we just called it
      else
        puts "❌ Unknown command: #{input}"
        puts "💡 Type '?' for help or 'x' to quit"
      end
      
      # Always show the main menu after any action (except when we break or explicitly skip)
      show_main_menu
    end
  end

  def show_main_menu
    puts "\n🎭 Chat CLI Main Menu"
    puts "=" * 40
    puts "📋 Available Commands:"
    puts "   1. prompts       - Load system prompts"
    puts "   2. continue      - Continue current conversation for more words"
    puts "   3. chat          - Start interactive chat session"
    puts "   4. save          - Save current conversation"
    puts "   5. voice on/off  - Toggle voice output"
    puts "   6. voices        - Select voice"
    puts "   7. api           - Switch API (openai/venice)"
    puts "   8. clear         - Clear conversation"
    puts "   9. keys          - Show API key status"
    puts "  10. convert       - Convert saved chat to audio"
    puts "  11. extended      - Generate extended dialogue (specify word count)"
    puts "   0 or ?           - Show this menu"
    puts "   00 or x          - Exit program"
    puts "=" * 40
    puts "🔇 Voice disabled by default (type 'voice on' to enable)"
    puts "🌐 Using #{@api_provider.upcase} API"
  end

  def continue_conversation
    puts "\n🔄 Continue Current Conversation"
    puts "=" * 50
    
    # Check if there's existing conversation content
    unless has_conversation_content?
      puts "❌ No conversation to continue!"
      puts "💡 Start with option 1 (prompts) or 11 (extended dialogue) first"
      return
    end
    
    # Show current conversation stats
    current_words = count_conversation_words
    puts "📊 Current conversation: #{current_words} words"
    
    # Get additional word count
    print "Enter additional words to generate (default: 1000): "
    additional_input = gets.chomp.strip
    additional_words = additional_input.empty? ? 1000 : additional_input.to_i
    
    if additional_words < 100
      puts "❌ Minimum additional words is 100"
      return
    end
    
    puts "\n🎯 Target: +#{additional_words} additional words"
    puts "📈 Total target: #{current_words + additional_words} words"
    
    # Optional user prompt
    puts "\n💭 Optional: Add a prompt to guide the continuation"
    puts "   (Press Enter to continue without additional prompt)"
    print "Prompt: "
    user_prompt = gets.chomp.strip
    
    unless user_prompt.empty?
      puts "✅ User prompt added: #{user_prompt}"
    end
    
    print "\nContinue? (y/n): "
    continue = gets.chomp.downcase
    return unless continue == 'y' || continue == 'yes'
    
    puts "\n🚀 Continuing conversation..."
    puts "⏸️ Press Ctrl+C to stop early"
    puts "-" * 50
    
    generate_continuation(additional_words, user_prompt)
  end

  def count_conversation_words
    # Count words in all non-system messages
    total_words = 0
    @conversation.each do |msg|
      next if msg[:role] == "system"
      total_words += count_words(msg[:content])
    end
    total_words
  end

  def generate_continuation(target_additional_words, user_prompt = "")
    starting_words = count_conversation_words
    max_response_tokens = determine_api_response_limit
    estimated_words_per_chunk = (max_response_tokens * 0.75).to_i
    
    puts "📊 Estimated words per response: #{estimated_words_per_chunk}"
    puts "📈 Estimated segments needed: #{(target_additional_words.to_f / estimated_words_per_chunk).ceil}"
    
    segment_count = 0
    words_added = 0
    
    begin
      # Add user prompt if provided
      unless user_prompt.empty?
        continuation_prompt = "#{user_prompt} Continue the dialogue naturally, maintaining character consistency and formatting as 'DADDY:' and 'BARRY:' with rich descriptions."
      else
        continuation_prompt = "Continue the dialogue naturally from where we left off. Maintain character consistency and keep the same engaging style with detailed descriptions. Format as 'DADDY:' and 'BARRY:' alternating speakers."
      end
      
      @conversation << { role: "user", content: continuation_prompt }
      
      loop do
        segment_count += 1
        puts "\n🔄 Generating continuation segment #{segment_count}..."
        
        # Make API request
        response = make_api_request
        
        if response['error']
          puts "❌ API Error: #{response['error']['message']}"
          break
        end
        
        if response['choices'] && response['choices'][0]
          segment_text = response['choices'][0]['message']['content']
          @conversation << { role: "assistant", content: segment_text }
          
          # Count words in this segment
          segment_words = count_words(segment_text)
          words_added += segment_words
          current_total = starting_words + words_added
          
          # Display current segment
          puts "\n📝 Segment #{segment_count} (#{segment_words} words):"
          puts "-" * 30
          display_roleplay_response(segment_text)
          puts "-" * 30
          puts "📊 Additional words: #{words_added}/#{target_additional_words}"
          puts "📈 Total conversation: #{current_total} words"
          
          # Check if we've reached target
          if words_added >= target_additional_words
            puts "\n🎉 Target additional words reached!"
            puts "📊 Added: #{words_added} words"
            puts "📈 Total conversation: #{current_total} words"
            break
          end
          
          # Generate next continuation prompt
          next_prompt = generate_continuation_prompt(segment_text, target_additional_words - words_added)
          @conversation << { role: "user", content: next_prompt }
          
          # Brief pause
          sleep(1)
          
        else
          puts "❌ Error: Unexpected response format"
          break
        end
      end
      
    rescue Interrupt
      puts "\n\n⏹️ Continuation stopped by user!"
    ensure
      puts "\n💾 Conversation continuation complete!"
      puts "📊 Words added: #{words_added}"
      puts "📈 Total conversation: #{starting_words + words_added} words"
      puts "🔢 Segments generated: #{segment_count}"
    end
  end

  def start_extended_dialogue
    puts "\n📝 Extended Dialogue Generation"
    puts "=" * 50
    
    # Get target word count
    print "Enter target word count (default: 2000): "
    target_input = gets.chomp.strip
    target_words = target_input.empty? ? 2000 : target_input.to_i
    
    if target_words < 100
      puts "❌ Minimum word count is 100 words"
      return
    end
    
    puts "\n🎯 Target: #{target_words} words"
    puts "🤖 Using #{@api_provider.upcase} API"
    puts "⚙️ Determining API response limits..."
    
    # Determine optimal chunk size based on API provider
    max_response_tokens = determine_api_response_limit
    estimated_words_per_chunk = (max_response_tokens * 0.75).to_i # ~75% of tokens are words
    
    puts "📊 Estimated words per response: #{estimated_words_per_chunk}"
    puts "📈 Estimated number of segments needed: #{(target_words.to_f / estimated_words_per_chunk).ceil}"
    
    print "\nContinue? (y/n): "
    continue = gets.chomp.downcase
    return unless continue == 'y' || continue == 'yes'
    
    puts "\n🚀 Starting extended dialogue generation..."
    puts "⏸️ Press Ctrl+C to stop early"
    puts "-" * 50
    
    generate_extended_dialogue(target_words, estimated_words_per_chunk)
  end

  def determine_api_response_limit
    case @api_provider
    when 'openai'
      # OpenAI typically allows up to 4096 tokens for most models
      return 1000 # Conservative estimate for max_tokens parameter
    when 'venice'
      # Venice.ai supports similar limits, based on their documentation
      return 1000 # Conservative estimate, could potentially go higher
    else
      return 1000 # Default fallback
    end
  end

  def generate_extended_dialogue(target_words, words_per_chunk)
    total_dialogue = ""
    current_words = 0
    segment_count = 0
    
    # Save current conversation state
    conversation_backup = @conversation.dup
    
    begin
      # Ensure we have system prompts loaded
      ensure_system_prompts_loaded
      
      # Initial prompt to start the dialogue
      initial_prompt = "Generate an engaging dialogue between Daddy and Barry. Format as 'DADDY:' and 'BARRY:' with detailed, immersive descriptions. Each response should be 3-6 sentences with rich detail about their interactions, feelings, and the environment around them. Start with DADDY speaking first."
      
      @conversation << { role: "user", content: initial_prompt }
      
      loop do
        segment_count += 1
        puts "\n🔄 Generating segment #{segment_count}..."
        
        # Make API request for this segment
        response = make_api_request
        
        if response['error']
          puts "❌ API Error: #{response['error']['message']}"
          break
        end
        
        if response['choices'] && response['choices'][0]
          segment_text = response['choices'][0]['message']['content']
          @conversation << { role: "assistant", content: segment_text }
          
          # Add to total dialogue
          total_dialogue += "\n" unless total_dialogue.empty?
          total_dialogue += segment_text
          
          # Count words in current total
          current_words = count_words(total_dialogue)
          
          # Display current segment
          puts "\n📝 Segment #{segment_count} (#{count_words(segment_text)} words):"
          puts "-" * 30
          display_roleplay_response(segment_text)
          puts "-" * 30
          puts "📊 Total words so far: #{current_words}/#{target_words}"
          
          # Check if we've reached target
          if current_words >= target_words
            puts "\n🎉 Target word count reached! Final count: #{current_words} words"
            break
          end
          
          # Generate continuation prompt
          continuation_prompt = generate_continuation_prompt(segment_text, target_words - current_words)
          @conversation << { role: "user", content: continuation_prompt }
          
          # Brief pause between segments
          sleep(1)
          
        else
          puts "❌ Error: Unexpected response format"
          break
        end
      end
      
    rescue Interrupt
      puts "\n\n⏹️ Extended dialogue generation stopped by user!"
    ensure
      # Restore original conversation if user wants
      puts "\n💾 Extended dialogue generation complete!"
      puts "📊 Final word count: #{current_words} words"
      puts "🔢 Segments generated: #{segment_count}"
      
      # Offer to save the extended dialogue
      puts "\nWould you like to:"
      puts "1. Save complete dialogue to file"
      puts "2. Keep dialogue in current conversation"
      puts "3. Restore original conversation"
      print "Choice (1-3): "
      
      choice = gets.chomp
      case choice
      when '1'
        save_chat_dialog  # Use the same save function for consistency
        @conversation = conversation_backup # Restore original
      when '2'
        puts "✅ Extended dialogue kept in conversation"
        # Keep current conversation state
      when '3', ''
        @conversation = conversation_backup
        puts "✅ Original conversation restored"
      else
        puts "❓ Invalid choice, keeping extended dialogue"
      end
    end
  end

  def generate_continuation_prompt(previous_segment, remaining_words)
    # Analyze the previous segment to create a contextual continuation
    prompts = [
      "Continue the dialogue naturally, building on the previous exchange. Maintain character consistency and develop the scene further with rich detail.",
      "Keep the conversation flowing with the next detailed exchanges. Focus on character development and emotional depth.",
      "Continue with more immersive dialogue that advances the relationship and story. Include sensory details and character reactions.",
      "Develop the scene further with engaging dialogue that builds on the previous interaction. Keep the emotional tone consistent.",
      "Continue the conversation with detailed responses that deepen the connection between the characters."
    ]
    
    base_prompt = prompts.sample
    word_guidance = remaining_words > 500 ? "Generate substantial content with rich descriptions." : "Begin wrapping up the dialogue naturally."
    
    "#{base_prompt} #{word_guidance} Continue formatting as 'DADDY:' and 'BARRY:' alternating speakers."
  end

  def count_words(text)
    # Count all words including character names, dialogue, and narrative
    text.split(/\s+/).reject(&:empty?).length
  end

  def display_roleplay_response(response)
    lines = response.split(/\n+/)

    lines.each do |line|
      line = line.strip
      next if line.empty?

      if line.match(/^(DADDY|BARRY|SAMMY):\s*(.+)$/i)
        character = $1.upcase
        dialogue = $2

        case character
        when "DADDY"
          puts "\n👨 DADDY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
        when "BARRY"
          puts "\n🐷 BARRY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
        when "SAMMY"
          puts "\n💅 SAMMY:"
          wrapped = wrap_text(dialogue)
          puts "#{wrapped}"
        end
      else
        puts "\n💬 #{line}"
      end
    end
  end

  # Rest of existing methods remain the same...
  def show_api_key_status
    puts "\n🔐 API Key Status:"
    openai_status = @openai_api_key && !@openai_api_key.empty? ? "✅ OpenAI: #{@openai_api_key[0..8]}..." : "❌ OpenAI: Not found"
    venice_status = @venice_api_key && !@venice_api_key.empty? ? "✅ Venice: #{@venice_api_key[0..8]}..." : "❌ Venice: Not found"
    puts "   #{openai_status}"
    puts "   #{venice_status}"
    puts "   Current: #{@api_provider.upcase}"
  end

  def clean_preview_text(content)
    # Remove common formatting characters and clean up the preview
    cleaned = content.gsub(/[#*{}]/, '').gsub(/\s+/, ' ').strip
    
    # Find a good breaking point around 80-100 characters
    if cleaned.length <= 100
      cleaned
    else
      # Try to break at a sentence or natural point
      truncated = cleaned[0..97]
      last_period = truncated.rindex('.')
      last_space = truncated.rindex(' ')
      
      if last_period && last_period > 60
        truncated[0..last_period]
      elsif last_space && last_space > 60
        truncated[0..last_space] + "..."
      else
        truncated + "..."
      end
    end
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
    puts "=" * 50

    prompts = []
    prompt_files.each do |file|
      name = File.basename(file, '.prompt')
      content = File.read(file).strip
      # Clean up the preview - remove excessive formatting and truncate nicely
      preview = clean_preview_text(content)
      prompts << { name: name, file: file, content: content, preview: preview }
    end

    prompts.each_with_index do |prompt, i|
      puts "#{(i+1).to_s.rjust(2)}. #{prompt[:name]}"
      puts "     #{prompt[:preview]}"
      puts ""
    end

    puts "🎤 Commands:"
    puts "   [number]         - Load prompt by number (e.g. 3)"
    puts "   [name]           - Load prompt by name (e.g. creative_writer)"
    puts "   b[number]        - Browse full prompt content (e.g. b3)"
    puts "   b[name]          - Browse by name (e.g. bcreative_writer)"
    puts "   x, quit, exit    - Return to main menu"
    puts "   ?, help          - Show this help"
    puts ""
    puts "💡 Tips:"
    puts "   - You can use partial names for quick matching"
    puts "   - Browse first to see the full prompt content"
    puts "   - Loading a prompt changes the AI's personality"
    puts "=" * 50
    
    loop do
      print "\nPrompt> "
      input = gets.chomp.strip

      case input
      when 'x', 'exit', 'quit'
        puts "📙 Returning to main menu"
        break
      when /^\d+$/
        index = input.to_i - 1
        if index >= 0 && index < prompts.length
          selected_prompt = prompts[index]
          load_system_prompt(selected_prompt[:content], selected_prompt[:name])
          break
        else
          puts "❌ Invalid number"
        end
      when /^b(\d+)$/
        index = $1.to_i - 1
        if index >= 0 && index < prompts.length
          puts "\n📋 Preview of '#{prompts[index][:name]}':"
          puts "-" * 40
          puts prompts[index][:content]
          puts "-" * 40
        else
          puts "❌ Invalid number"
        end
      else
        # Try to match by name
        matching_prompts = prompts.select { |p| p[:name].downcase.include?(input.downcase) }
        if matching_prompts.length == 1
          selected_prompt = matching_prompts.first
          load_system_prompt(selected_prompt[:content], selected_prompt[:name])
          break
        elsif matching_prompts.length > 1
          puts "Multiple matches found:"
          matching_prompts.each { |p| puts "  - #{p[:name]}" }
        else
          puts "❌ No matching prompts found"
        end
      end
    end
  end

  def load_system_prompt(content, name)
    # Load standard system prompts from file
    system_prompts_file = "system_prompts.txt"
    standard_prompts = ""
    
    if File.exist?(system_prompts_file)
      standard_prompts = File.read(system_prompts_file).strip
    else
      puts "⚠️ Warning: #{system_prompts_file} not found - using built-in defaults"
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
    puts "📄 Standard prompts automatically added from #{system_prompts_file}"
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
        puts "\n🔚 Ending chat session..."
        offer_save_on_exit if has_conversation_content?
        @in_chat_session = false
        puts "📙 Returning to main menu"
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
      when /^auto(?:\s+(\d+))?$/
        # Auto-extend the conversation
        word_count = $1 ? $1.to_i : 1000
        auto_extend_in_chat(word_count)
      when /^extend(?:\s+(\d+))?$/
        # Alias for auto
        word_count = $1 ? $1.to_i : 1000
        auto_extend_in_chat(word_count)
      when ''
        next
      else
        send_message(input)
      end
    end
  end

  def auto_extend_in_chat(word_count)
    puts "\n🤖 Auto-extending conversation for #{word_count} additional words..."
    puts "⏸️ Press Ctrl+C to stop early"
    puts "-" * 50
    
    starting_words = count_conversation_words
    puts "📊 Current conversation: #{starting_words} words"
    puts "🎯 Target: +#{word_count} additional words"
    
    # Use the existing continuation logic
    begin
      generate_continuation(word_count, "")
      
      final_words = count_conversation_words
      words_added = final_words - starting_words
      
      puts "\n🎉 Auto-extension complete!"
      puts "📊 Added #{words_added} words"
      puts "📈 Total conversation: #{final_words} words"
      puts "💬 You can continue chatting or type 'auto' again for more extension"
      
    rescue Interrupt
      puts "\n\n⏹️ Auto-extension stopped by user!"
      puts "💬 Returning to chat mode - you can continue the conversation manually"
    end
  end

  def show_chat_help
    puts "\n🆘 Chat Session Help"
    puts "=" * 35
    puts "📝 Chat Commands:"
    puts "   [message]        - Send message to AI"
    puts "   ?                - Show this help"
    puts "   x                - End chat session (return to main menu)"
    puts "   save             - Save current conversation"
    puts "   clear            - Clear conversation history"
    puts "   voice on/off     - Toggle voice output"
    puts "   auto [words]     - Auto-extend dialogue (default: 1000 words)"
    puts "   extend [words]   - Same as auto (alias)"
    puts ""
    puts "💡 Tips:"
    puts "   - Just type naturally to chat with the AI"
    puts "   - Use 'auto 500' to let AI continue the story for 500 words"
    puts "   - Use 'x' to end this chat and return to main menu"
    puts "   - Your conversation will be saved if you choose"
    puts "=" * 35
  end

  def ensure_system_prompts_loaded
    has_system_prompt = @conversation.any? { |msg| msg[:role] == "system" }
    unless has_system_prompt
      puts "📄 Loading default system prompts for chat session..."
      load_default_system_prompts
    end
  end

  def load_default_system_prompts
    system_prompts_file = "system_prompts.txt"
    
    if File.exist?(system_prompts_file)
      standard_prompts = File.read(system_prompts_file).strip
      puts "✅ Loaded system prompts from #{system_prompts_file}"
    else
      puts "⚠️ Warning: #{system_prompts_file} not found - using built-in defaults"
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
    puts "\n🎵 Voice Selection"
    puts "=" * 30
    
    # Available voices (these would work with system 'say' command on macOS)
    voices = [
      { name: "Daniel", description: "Clear male voice" },
      { name: "Samantha", description: "Clear female voice" },
      { name: "Alex", description: "Default male voice" },
      { name: "Victoria", description: "British female voice" },
      { name: "Fred", description: "Older male voice" },
      { name: "Vicki", description: "Female voice" },
      { name: "Princess", description: "Younger female voice" }
    ]
    
    puts "Available voices:"
    voices.each_with_index do |voice, i|
      current = voice[:name] == @voice_name ? " (current)" : ""
      puts "#{(i+1).to_s.rjust(2)}. #{voice[:name].ljust(12)} - #{voice[:description]}#{current}"
    end
    
    puts "\n🎤 Commands:"
    puts "   [number]    - Select voice by number"
    puts "   t[number]   - Test voice (e.g. t1)"
    puts "   x, quit     - Return to main menu"
    
    loop do
      print "\nVoice> "
      input = gets.chomp.strip
      
      case input
      when 'x', 'quit', 'exit'
        puts "📙 Returning to main menu"
        break
      when /^t(\d+)$/
        index = $1.to_i - 1
        if index >= 0 && index < voices.length
          test_voice = voices[index][:name]
          puts "🔊 Testing voice: #{test_voice}"
          system("say -v '#{test_voice}' 'Hello! This is a test of the #{test_voice} voice.'")
        else
          puts "❌ Invalid voice number"
        end
      when /^\d+$/
        index = input.to_i - 1
        if index >= 0 && index < voices.length
          @voice_name = voices[index][:name]
          puts "✅ Voice changed to: #{@voice_name}"
          if @voice_enabled
            system("say -v '#{@voice_name}' 'Voice changed to #{@voice_name}'")
          end
          break
        else
          puts "❌ Invalid voice number"
        end
      else
        puts "❌ Unknown command. Try a number, t[number] to test, or 'x' to exit"
      end
    end
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
      puts "⚠️ Note: Voice generation will use OpenAI TTS (if available) or system voice"
    end

    if @voice_enabled && respond_to?(:speak_text)
      speak_text("Switched to #{provider} API")
    end
  end

  def clear_conversation
    # Store API provider before clearing
    current_provider = @api_provider
    @conversation.clear
    @api_provider = current_provider
    puts "🗑️ Conversation cleared"
  end

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
    
    # Generate filename with timestamp first for true chronological sorting
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    word_count = count_conversation_words
    filename = "#{timestamp}_dialogue_#{word_count}words.txt"
    filepath = File.join(chats_dir, filename)
    
    # Format the complete dialogue for saving (includes all extensions)
    formatted_content = format_conversation_for_save(word_count)
    
    # Generate synopsis of prompts using Venice.ai
    puts "🤖 Generating prompt synopsis with Venice.ai..."
    synopsis = generate_prompt_synopsis
    
    # Add synopsis to the content if generated successfully
    if synopsis
      formatted_content += "\n\n" + "=" * 60 + "\n"
      formatted_content += "# PROMPT SYNOPSIS (Generated by Venice.ai)\n"
      formatted_content += "=" * 60 + "\n\n"
      formatted_content += synopsis
    end
    
    File.write(filepath, formatted_content)
    puts "✅ Complete dialogue saved to: #{filepath}"
    puts "📝 File contains #{word_count} words total"
    puts "📋 Includes prompt synopsis" if synopsis
  end

  def generate_prompt_synopsis
    return nil unless @api_provider == 'venice' && @venice_api_key && !@venice_api_key.empty?
    
    begin
      puts "🔍 Analyzing conversation for prompt synopsis..."
      
      # Create a request to Venice.ai asking for prompt analysis
      analysis_prompt = <<~PROMPT
        Please analyze this conversation and provide a concise synopsis of:
        1. The main system prompts/instructions that were given
        2. The character roles and personalities established
        3. The key themes and scenarios discussed
        4. Any specific writing style or format instructions used
        
        Keep the synopsis under 500 words and focus on the prompting strategy used.
        
        Here is the conversation to analyze:
        
        #{format_conversation_for_analysis}
      PROMPT
      
      # Make API request for synopsis
      synopsis_conversation = [
        { role: "system", content: "You are an AI assistant that analyzes conversations to extract and summarize the prompting strategies used." },
        { role: "user", content: analysis_prompt }
      ]
      
      response = make_venice_synopsis_request(synopsis_conversation)
      
      if response['choices'] && response['choices'][0]
        synopsis_text = response['choices'][0]['message']['content']
        puts "✅ Synopsis generated successfully"
        return synopsis_text
      else
        puts "⚠️ Could not generate synopsis - unexpected response format"
        return nil
      end
      
    rescue => e
      puts "⚠️ Could not generate synopsis: #{e.message}"
      return nil
    end
  end

  def format_conversation_for_analysis
    # Format conversation for analysis, keeping it concise
    analysis_content = ""
    
    @conversation.each_with_index do |msg, i|
      case msg[:role]
      when "system"
        analysis_content += "[SYSTEM PROMPT]: #{msg[:content]}\n\n"
      when "user"
        # Only include first few and last few user messages to keep it manageable
        if i < 5 || i >= @conversation.length - 3
          analysis_content += "[USER]: #{msg[:content]}\n\n"
        elsif i == 5
          analysis_content += "[... conversation continues ...]\n\n"
        end
      when "assistant"
        # Only include first few AI responses for context
        if i < 6
          content_preview = msg[:content].length > 200 ? msg[:content][0..197] + "..." : msg[:content]
          analysis_content += "[AI]: #{content_preview}\n\n"
        end
      end
    end
    
    analysis_content
  end

  def make_venice_synopsis_request(messages)
    uri = URI(VENICE_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@venice_api_key}"
    request['Content-Type'] = 'application/json'

    payload = {
      model: "llama-3.3-70b",
      messages: messages,
      max_tokens: 800,  # Limit for synopsis
      temperature: 0.3, # Lower temperature for more focused analysis
      venice_parameters: {
        include_venice_system_prompt: false,
        top_p: 0.8
      }
    }

    request.body = payload.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

  def format_conversation_for_save(word_count)
    # Content first - no header metadata
    content = ""
    @conversation.each do |msg|
      next if msg[:role] == "system"
      
      case msg[:role]
      when "user"
        content += "USER: #{msg[:content]}\n\n"
      when "assistant"
        content += "AI: #{msg[:content]}\n\n"
      end
    end
    
    # All metadata at the END of the file
    footer = <<~FOOTER
      
      #{"-" * 60}
      # Complete Dialogue - Saved #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
      # Word Count: #{word_count} words
      # Generated using: #{@api_provider.upcase} API
      # End of Complete Dialogue
    FOOTER
    
    content + footer
  end

  def convert_saved_chat_to_audio
    chats_dir = "./chats"
    
    unless Dir.exist?(chats_dir)
      puts "❌ No chats directory found!"
      puts "💡 Save some conversations first"
      return
    end
    
    # Get list of chat files
    chat_files = Dir.glob(File.join(chats_dir, "*.txt")).sort_by { |f| File.mtime(f) }.reverse
    
    if chat_files.empty?
      puts "❌ No chat files found in ./chats/"
      puts "💡 Save some conversations first"
      return
    end
    
    puts "\n🔊 Convert Chat to Audio"
    puts "=" * 40
    puts "Select a chat file to convert:"
    
    chat_files.each_with_index do |file, i|
      filename = File.basename(file)
      file_size = File.size(file)
      puts "#{(i+1).to_s.rjust(2)}. #{filename} (#{file_size} bytes)"
    end
    
    print "\nSelect file (1-#{chat_files.length}) or 'x' to cancel: "
    choice = gets.chomp.strip
    
    if choice.downcase == 'x'
      puts "📙 Cancelled"
      return
    end
    
    if choice.match?(/^\d+$/) && (1..chat_files.length).include?(choice.to_i)
      selected_file = chat_files[choice.to_i - 1]
      puts "🎤 Audio conversion selected: #{File.basename(selected_file)}"
      
      # Use the existing TTS CLI functionality
      begin
        # Add the lib directory to load path if not already there
        lib_paths = [
          File.expand_path('../../lib', __FILE__),
          File.expand_path('../lib', __FILE__),
          File.expand_path('./lib', __FILE__),
          File.expand_path('../v2/lib', __FILE__)
        ]
        
        lib_paths.each do |path|
          $LOAD_PATH.unshift(path) if Dir.exist?(path) && !$LOAD_PATH.include?(path)
        end
        
        require 'tts_cli'
        
        puts "🚀 Launching TTS conversion using existing TTS system..."
        
        # Create TTS CLI instance and process the selected file directly
        tts_cli = V2::TTSCLI.new
        tts_cli.process_chat_file(selected_file)
        
        puts "✅ TTS conversion completed!"
        
      rescue LoadError => e
        puts "⚠️ Could not load TTS module: #{e.message}"
        puts "💡 Make sure the v2/lib directory structure is available"
        puts "📁 Expected: ./v2/lib/tts_cli.rb"
      rescue => e
        puts "❌ Error during TTS conversion: #{e.message}"
        puts "🔧 Debug info: #{e.backtrace.first}" if ENV['DEBUG']
      end
    else
      puts "❌ Invalid selection"
    end
  end

  def offer_save_on_exit
    return unless has_conversation_content?

    puts "\n💾 Would you like to save this conversation before exiting? (y/n)"
    print "Save chat? > "
    
    response = gets.chomp.downcase
    
    if response == 'y' || response == 'yes'
      save_chat_dialog
    elsif response == 'n' || response == 'no'
      puts "🚫 Conversation not saved."
    else
      puts "🤷 I'll take that as a no. Conversation not saved."
    end
  end

  def has_conversation_content?
    @conversation.any? { |msg| msg[:role] != "system" }
  end
end

if __FILE__ == $0
  puts "version v#{ChatGPTCLI::VERSION}"
  ChatGPTCLI.new.start
end