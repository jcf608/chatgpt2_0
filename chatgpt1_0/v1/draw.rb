#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'base64'
require 'fileutils'

class ChatToImageGenerator
  OPENAI_CHAT_URL = 'https://api.openai.com/v1/chat/completions'
  VENICE_IMAGE_URL = 'https://api.venice.ai/api/v1/images/generations'
  OPENAI_IMAGE_URL = 'https://api.openai.com/v1/images/generations'
  AUTOMATIC1111_URL = 'http://127.0.0.1:7860'  # Default A1111 WebUI address
  STABILITY_API_URL = 'https://api.stability.ai/v1/generation/stable-diffusion-v1-6/text-to-image'

  def initialize
    @openai_api_key = load_api_key('openAI_api_key', 'OPENAI_API_KEY')
    @venice_api_key = load_api_key('venice_api_key', 'VENICE_API_KEY')
    @stability_api_key = load_api_key('stability_api_key', 'STABILITY_API_KEY')
    @chats_dir = './chats'
    @output_dir = './illustrations'
    @prompts_dir = './prompts'
    @image_provider = 'automatic1111'  # Default to A1111 (free and powerful!)
    @a1111_host = 'http://127.0.0.1:7860'  # Default A1111 address

    FileUtils.mkdir_p(@output_dir)
    FileUtils.mkdir_p(@prompts_dir)

    unless @openai_api_key
      puts "❌ No OpenAI API key found!"
      puts "Create 'openAI_api_key' file or set OPENAI_API_KEY environment variable"
      exit 1
    end
  end

  def load_api_key(file_name, env_var)
    if File.exist?(file_name)
      File.read(file_name).strip
    else
      ENV[env_var]
    end
  end

  def run
    puts "🎨 Welcome to Chat-to-Image Generator! 🎨"

    loop do
      begin
        show_main_menu
        choice = get_user_choice

        case choice.downcase
        when 'q', 'quit', 'exit'
          puts "Thanks for using the Chat-to-Image Generator! ✨🎨"
          break
        when 'a', 'auto', 'automatic1111'
          toggle_provider('automatic1111')
        when 's', 'stability'
          toggle_provider('stability')
        when 'v', 'venice'
          toggle_provider('venice')
        when 'o', 'openai'
          toggle_provider('openai')
        when 'h', 'help'
          show_help
        when 'i', 'import'
          import_prompts_menu
        when 'e', 'export'
          export_last_prompts
        else
          if choice.match?(/^\d+$/)
            process_chat_selection(choice.to_i)
          else
            puts "❌ Invalid option! Try again, honey! 💅"
            sleep(1)
          end
        end
      rescue Interrupt
        puts "\n\n🛑 Interrupted! Returning to main menu..."
        puts "Press 'q' to quit properly! 💅"
        sleep(1)
      rescue => e
        puts "\n❌ Oops! Something went wrong: #{e.message}"
        puts "💡 Don't worry, we'll keep going! ✨"
        sleep(2)
      end
    end
  end

  def show_main_menu
    unless Dir.exist?(@chats_dir)
      puts "❌ Chats directory './chats' not found!"
      puts "Create it with: mkdir -p chats"
      exit 1
    end

    chat_files = Dir.glob("#{@chats_dir}/*.txt").sort_by { |f| File.mtime(f) }  # Oldest first

    if chat_files.empty?
      puts "📂 No .txt files found in #{@chats_dir}/"
      puts "Save some chat conversations first!"
      exit 1
    end

    puts "\n" + "🎨" * 50
    puts "✨ CHAT-TO-IMAGE GENERATOR ✨"
    puts "🖼️  Turn your conversations into ART! 🖼️"
    puts "🎨" * 50
    puts "🤖 AI Provider: #{@image_provider.upcase} #{get_provider_emoji}"
    puts "📁 Found #{chat_files.length} chat files (oldest first)"
    puts "=" * 100

    puts "\n📚 Available Chat Files:"
    puts "-" * 100

    chats = []
    chat_files.each_with_index do |file, index|
      name = File.basename(file, '.txt')
      size = File.size(file)
      mtime = File.mtime(file)
      preview = get_file_preview(file)

      chats << {
        index: index + 1,
        name: name,
        file: file,
        size: size,
        mtime: mtime,
        preview: preview
      }
    end

    # Display in two columns
    chats.each_slice(2).with_index do |chat_pair, row_index|
      left_chat = chat_pair[0]
      right_chat = chat_pair[1]

      # Left column
      left_size_kb = (left_chat[:size] / 1024.0).round(1)
      left_time_str = left_chat[:mtime].strftime("%m/%d %H:%M")
      left_name = left_chat[:name].length > 35 ? "#{left_chat[:name][0..32]}..." : left_chat[:name]
      left_line = "#{left_chat[:index].to_s.rjust(2)}. #{left_name.ljust(36)} #{left_time_str} #{left_size_kb.to_s.rjust(4)}KB"

      if right_chat
        # Right column
        right_size_kb = (right_chat[:size] / 1024.0).round(1)
        right_time_str = right_chat[:mtime].strftime("%m/%d %H:%M")
        right_name = right_chat[:name].length > 35 ? "#{right_chat[:name][0..32]}..." : right_chat[:name]
        right_line = "#{right_chat[:index].to_s.rjust(2)}. #{right_name.ljust(36)} #{right_time_str} #{right_size_kb.to_s.rjust(4)}KB"

        puts "#{left_line.ljust(50)} #{right_line}"
      else
        puts left_line
      end
    end

    puts "\n" + "=" * 100
    puts "🎯 OPTIONS:"
    puts "  1-#{chats.length}. Select chat to illustrate"
    puts "  i. Import existing prompts from file"
    puts "  e. Export last generated prompts"
    puts "  a. Switch to Automatic1111 (local & free!) 🏠"
    puts "  s. Switch to Stability AI (cloud premium!) ☁️"
    puts "  v. Switch to Venice AI (budget friendly!) 💰"
    puts "  o. Switch to OpenAI (luxury option!) 💎"
    puts "  h. Show help"
    puts "  q. Quit"
    puts "=" * 100

    @available_chats = chats
  end

  def get_provider_emoji
    case @image_provider
    when 'automatic1111'
      '(Local Powerhouse! 🏠🔥)'
    when 'stability'
      '(Cloud Premium! ☁️💎)'
    when 'venice'
      '(Budget Queen! 💰)'
    when 'openai'
      '(Premium Luxury! 💎)'
    else
      '(Unknown! 🤔)'
    end
  end

  def get_file_preview(filename)
    begin
      content = File.read(filename, encoding: 'UTF-8')

      # Look for first user message
      if content.match(/👤 USER:\s*(.+?)(?=\n|$)/m)
        preview = $1.strip
        return preview.length > 60 ? "#{preview[0..57]}..." : preview
      end

      # Fallback to first non-header line
      lines = content.split("\n")
      content_line = lines.find { |line| !line.match(/^[=\-🎭📚🎤]/) && line.strip.length > 10 }

      if content_line
        preview = content_line.strip
        return preview.length > 60 ? "#{preview[0..57]}..." : preview
      end

      return "Chat conversation"
    rescue
      return "Unable to preview"
    end
  end

  def get_user_choice
    print "\n🎨 Your choice, gorgeous: "
    gets.chomp
  end

  def test_automatic1111_connection
    begin
      uri = URI("#{@a1111_host}/sdapi/v1/options")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      return response.code == '200'
    rescue
      return false
    end
  end

  def toggle_provider(provider)
    case provider
    when 'automatic1111'
      if test_automatic1111_connection
        @image_provider = 'automatic1111'
        puts "✅ Switched to Automatic1111! (Local AI beast! 🏠🔥)"
      else
        puts "❌ Can't connect to Automatic1111 at #{@a1111_host}"
        puts "💡 Make sure A1111 WebUI is running with --api flag!"
        puts "   Example: python launch.py --api"
      end
    when 'stability'
      if @stability_api_key
        @image_provider = 'stability'
        puts "✅ Switched to Stability AI! (Cloud powerhouse! ☁️💎)"
      else
        puts "❌ Stability API key not found! Add 'stability_api_key' file or STABILITY_API_KEY env var"
      end
    when 'venice'
      if @venice_api_key
        @image_provider = 'venice'
        puts "✅ Switched to Venice AI! (Budget-friendly beast! 💰✨)"
      else
        puts "❌ Venice API key not found! Add 'venice_api_key' file or VENICE_API_KEY env var"
      end
    when 'openai'
      @image_provider = 'openai'
      puts "✅ Switched to OpenAI! (Premium luxury mode! 💎✨)"
    end
  end

  def process_chat_selection(choice)
    if choice < 1 || choice > @available_chats.length
      puts "❌ Invalid selection! Pick a number between 1 and #{@available_chats.length}, babe!"
      return
    end

    selected_chat = @available_chats[choice - 1]
    puts "\n🎯 Selected: #{selected_chat[:name]}"
    puts "📄 Analyzing chat content..."

    # Read and analyze the chat file
    content = File.read(selected_chat[:file])
    cleaned_content = clean_chat_content(content)

    # Generate prompts using AI
    puts "🤖 Generating creative prompts with AI..."
    prompts = generate_image_prompts(cleaned_content, selected_chat[:name])

    if prompts && prompts.length > 0
      puts "\n🎨 Generated #{prompts.length} Fabulous Prompts:"
      puts "=" * 70

      prompts.each_with_index do |prompt, i|
        puts "\n#{i + 1}. 🎭 #{prompt[:title]}"
        puts "   📝 #{prompt[:description]}"
        puts "   🎨 Style: #{prompt[:style]}"
        puts "   ✨ Prompt: \"#{prompt[:prompt][0..100]}#{prompt[:prompt].length > 100 ? '...' : ''}\""
      end

      puts "\n" + "=" * 70
      puts "🚀 Generating ALL #{prompts.length} images with #{@image_provider.upcase}..."
      puts "⏳ This might take a moment, darling..."

      # Generate all images
      success_count = 0
      @last_generated_prompts = prompts  # Store for potential export

      prompts.each_with_index do |prompt, i|
        puts "\n🖼️  Creating image #{i + 1}/#{prompts.length}: #{prompt[:title]}"

        if generate_image(prompt, selected_chat[:name], i + 1)
          success_count += 1
          puts "✅ Success! #{success_count}/#{prompts.length} complete"
        else
          puts "❌ Failed to generate image #{i + 1}"
        end

        sleep(1) # Brief pause between requests
      end

      puts "\n🎉 FINISHED! Generated #{success_count}/#{prompts.length} images!"
      puts "📁 Check your #{@output_dir} folder for the gorgeous results! ✨"

    else
      puts "❌ Failed to generate prompts. Try again, sugar!"
    end

    puts "\n" + "🎨" * 30
    puts "Press ENTER to return to main menu..."
    gets
  end

  def clean_chat_content(content)
    # Remove headers and format markers
    processed = content.gsub(/^[=\-]{10,}.*$/, '')
    processed = processed.gsub(/^Date:.*$/, '')
    processed = processed.gsub(/^Voice:.*$/, '')
    processed = processed.gsub(/^API:.*$/, '')

    # Keep role markers but clean them up
    processed = processed.gsub(/^🎭 SYSTEM PROMPT:/, 'SYSTEM:')
    processed = processed.gsub(/^👤 USER:/, 'USER:')
    processed = processed.gsub(/^🤖 AI:/, 'AI:')
    processed = processed.gsub(/^👨 DADDY:/, 'DADDY:')
    processed = processed.gsub(/^🐷 SAMMY:/, 'SAMMY:')

    # Limit length for API (keep most recent content)
    if processed.length > 4000
      processed = processed[-4000..-1]
    end

    processed.strip
  end

  def generate_image_prompts(chat_content, chat_name)
    begin
      uri = URI(OPENAI_CHAT_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 45

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@openai_api_key}"
      request['Content-Type'] = 'application/json'

      system_prompt = <<~PROMPT
        You are a creative AI that analyzes conversations and creates vivid, artistic image prompts.
        
        Analyze the provided chat conversation and create exactly 3 distinct, creative image prompts that capture:
        1. The main visual theme or mood of the conversation
        2. Key concepts, subjects, or emotions discussed
        3. The overall atmosphere or tone
        
        Make the prompts artistic, visually striking, and suitable for AI image generation.
        Avoid explicit adult content - focus on artistic, abstract, or metaphorical representations.
        
        For each prompt, provide:
        - title: A catchy 3-6 word title
        - description: 1-2 sentence explanation
        - style: Art style (realistic, fantasy, abstract, impressionist, surreal, etc.)
        - prompt: Detailed 80-120 word prompt perfect for AI image generation
        
        Return as JSON array with these exact fields. Make it creative and visually stunning!
      PROMPT

      user_prompt = "Chat conversation to analyze:\n\n#{chat_content}"

      payload = {
        model: "gpt-4",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.9,
        max_tokens: 2000
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        result = JSON.parse(response.body)

        if result['choices'] && result['choices'][0] && result['choices'][0]['message']
          content = result['choices'][0]['message']['content']

          # Try to parse JSON from the response
          begin
            # Extract JSON if it's wrapped in markdown
            json_match = content.match(/```json\s*(.*?)\s*```/m)
            json_content = json_match ? json_match[1] : content

            prompts_data = JSON.parse(json_content)

            # Convert to our format
            return prompts_data.map do |p|
              {
                title: p['title'] || 'Untitled Masterpiece',
                description: p['description'] || 'Generated from chat analysis',
                style: p['style'] || 'artistic',
                prompt: p['prompt'] || 'Creative visual interpretation of the conversation themes'
              }
            end
          rescue JSON::ParserError
            puts "⚠️  AI response wasn't valid JSON, creating fallback prompts..."
            return create_fallback_prompts(chat_name)
          end
        end
      else
        puts "❌ OpenAI API error: #{response.code}"
        return create_fallback_prompts(chat_name)
      end

    rescue => e
      puts "❌ Error calling AI: #{e.message}"
      return create_fallback_prompts(chat_name)
    end
  end

  def create_fallback_prompts(chat_name)
    [
      {
        title: "Conversation Essence",
        description: "Abstract representation of the chat's emotional core",
        style: "abstract expressionist",
        prompt: "abstract expressionist painting with flowing colors and dynamic brushstrokes representing human communication, dialogue, and connection. Warm and cool tones interweaving, suggesting the back-and-forth nature of conversation, with areas of intensity and calm reflecting emotional peaks and valleys in human interaction"
      },
      {
        title: "Digital Dialogue",
        description: "Modern interpretation of AI-human communication",
        style: "digital art",
        prompt: "sleek digital art piece showing the intersection of human and artificial intelligence in communication. Geometric patterns mixed with organic flowing forms, holographic elements, glowing text fragments floating in space, representing the digital age of conversation and connection between minds"
      },
      {
        title: "Emotional Landscape",
        description: "Visual metaphor for the conversation's emotional journey",
        style: "surreal landscape",
        prompt: "surreal landscape where the terrain itself reflects emotional states and conversational flow. Rolling hills that shift between colors representing different moods, rivers of light carrying words and thoughts, trees that bend and sway with the rhythm of dialogue, under a sky that mirrors the overall tone of human connection"
      }
    ]
  end

  def generate_image(prompt_data, chat_name, image_number)
    case @image_provider
    when 'automatic1111'
      generate_with_automatic1111(prompt_data, chat_name, image_number)
    when 'stability'
      generate_with_stability(prompt_data, chat_name, image_number)
    when 'venice'
      generate_with_venice(prompt_data, chat_name, image_number)
    else
      generate_with_openai(prompt_data, chat_name, image_number)
    end
  end

  def generate_with_automatic1111(prompt_data, chat_name, image_number)
    begin
      uri = URI("#{@a1111_host}/sdapi/v1/txt2img")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120  # A1111 can be slow

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'

      # Enhanced prompt with style
      enhanced_prompt = "#{prompt_data[:prompt]}, #{prompt_data[:style]} style, highly detailed, masterpiece, best quality"
      negative_prompt = "worst quality, low quality, normal quality, lowres, low details, oversaturated, undersaturated, overexposed, underexposed"

      payload = {
        prompt: enhanced_prompt,
        negative_prompt: negative_prompt,
        steps: 30,
        cfg_scale: 7.5,
        width: 1024,
        height: 1024,
        sampler_name: "DPM++ 2M Karras",
        seed: -1,
        batch_size: 1,
        n_iter: 1
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        result = JSON.parse(response.body)

        if result['images'] && result['images'][0]
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          safe_title = sanitize_filename(prompt_data[:title])
          safe_chat = sanitize_filename(chat_name)
          filename = "a1111_#{safe_chat}_#{image_number}_#{safe_title}_#{timestamp}.png"
          filepath = File.join(@output_dir, filename)

          image_data = Base64.decode64(result['images'][0])
          File.write(filepath, image_data, mode: 'wb')

          puts "💾 Saved: #{filename}"
          return true
        end
      else
        puts "❌ Automatic1111 API error: #{response.code}"
        return false
      end

    rescue => e
      puts "❌ Automatic1111 error: #{e.message}"
      return false
    end
  end

  def generate_with_stability(prompt_data, chat_name, image_number)
    begin
      uri = URI(STABILITY_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@stability_api_key}"
      request['Content-Type'] = 'application/json'

      enhanced_prompt = "#{prompt_data[:prompt]}, #{prompt_data[:style]} style, highly detailed, professional quality"

      payload = {
        text_prompts: [
          {
            text: enhanced_prompt,
            weight: 1
          },
          {
            text: "blurry, bad quality, distorted, ugly",
            weight: -1
          }
        ],
        cfg_scale: 7,
        height: 1024,
        width: 1024,
        samples: 1,
        steps: 30
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        result = JSON.parse(response.body)

        if result['artifacts'] && result['artifacts'][0] && result['artifacts'][0]['base64']
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          safe_title = sanitize_filename(prompt_data[:title])
          safe_chat = sanitize_filename(chat_name)
          filename = "stability_#{safe_chat}_#{image_number}_#{safe_title}_#{timestamp}.png"
          filepath = File.join(@output_dir, filename)

          image_data = Base64.decode64(result['artifacts'][0]['base64'])
          File.write(filepath, image_data, mode: 'wb')

          puts "💾 Saved: #{filename}"
          return true
        end
      else
        puts "❌ Stability AI error: #{response.code}"
        return false
      end

    rescue => e
      puts "❌ Stability AI error: #{e.message}"
      return false
    end
  end

  def generate_with_venice(prompt_data, chat_name, image_number)
    begin
      uri = URI(VENICE_IMAGE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@venice_api_key}"
      request['Content-Type'] = 'application/json'

      enhanced_prompt = "#{prompt_data[:prompt]}, #{prompt_data[:style]} style, highly detailed, artistic masterpiece"

      payload = {
        prompt: enhanced_prompt,
        model: "venice-v1",
        n: 1,
        size: "1024x1024",
        response_format: "b64_json"
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        result = JSON.parse(response.body)

        if result['data'] && result['data'][0] && result['data'][0]['b64_json']
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          safe_title = sanitize_filename(prompt_data[:title])
          safe_chat = sanitize_filename(chat_name)
          filename = "venice_#{safe_chat}_#{image_number}_#{safe_title}_#{timestamp}.png"
          filepath = File.join(@output_dir, filename)

          image_data = Base64.decode64(result['data'][0]['b64_json'])
          File.write(filepath, image_data, mode: 'wb')

          puts "💾 Saved: #{filename}"
          return true
        end
      else
        puts "❌ Venice API error: #{response.code}"
        return false
      end

    rescue => e
      puts "❌ Venice error: #{e.message}"
      return false
    end
  end

  def generate_with_openai(prompt_data, chat_name, image_number)
    begin
      uri = URI(OPENAI_IMAGE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@openai_api_key}"
      request['Content-Type'] = 'application/json'

      enhanced_prompt = "#{prompt_data[:prompt]}, #{prompt_data[:style]} style, highly detailed, artistic quality"

      payload = {
        model: "dall-e-3",
        prompt: enhanced_prompt,
        n: 1,
        size: "1024x1024",
        quality: "standard",
        response_format: "b64_json"
      }

      request.body = payload.to_json
      response = http.request(request)

      if response.code == '200'
        result = JSON.parse(response.body)

        if result['data'] && result['data'][0] && result['data'][0]['b64_json']
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          safe_title = sanitize_filename(prompt_data[:title])
          safe_chat = sanitize_filename(chat_name)
          filename = "openai_#{safe_chat}_#{image_number}_#{safe_title}_#{timestamp}.png"
          filepath = File.join(@output_dir, filename)

          image_data = Base64.decode64(result['data'][0]['b64_json'])
          File.write(filepath, image_data, mode: 'wb')

          puts "💾 Saved: #{filename}"
          return true
        end
      else
        puts "❌ OpenAI API error: #{response.code}"
        return false
      end

    rescue => e
      puts "❌ OpenAI error: #{e.message}"
      return false
    end
  end

  def sanitize_filename(text)
    text.gsub(/[^\w\s-]/, '').gsub(/\s+/, '_').downcase[0..25]
  end

  def import_prompts_menu
    prompt_files = Dir.glob("#{@prompts_dir}/*.prompt").sort_by { |f| File.mtime(f) }.reverse

    if prompt_files.empty?
      puts "\n❌ No .prompt files found in #{@prompts_dir}/"
      puts "💡 Export some prompts first or create .prompt files manually!"
      return
    end

    puts "\n📥 IMPORT PROMPTS"
    puts "=" * 50
    puts "Found #{prompt_files.length} prompt files:"
    puts

    prompt_files.each_with_index do |file, i|
      name = File.basename(file, '.prompt')
      mtime = File.mtime(file).strftime("%m/%d %H:%M")
      size = File.size(file)
      puts "#{(i + 1).to_s.rjust(2)}. #{name.ljust(40)} #{mtime} #{(size/1024.0).round(1)}KB"
    end

    puts "\n🎨 Select prompt file to import (1-#{prompt_files.length}) or 'q' to cancel:"
    print "> "
    choice = gets.chomp.downcase

    if choice == 'q'
      return
    end

    if choice.match?(/^\d+$/) && (1..prompt_files.length).include?(choice.to_i)
      selected_file = prompt_files[choice.to_i - 1]
      import_and_generate(selected_file)
    else
      puts "❌ Invalid selection!"
    end
  end

  def import_and_generate(prompt_file)
    begin
      puts "\n📖 Loading prompts from: #{File.basename(prompt_file)}"

      content = File.read(prompt_file)
      prompts = parse_prompt_file(content)

      if prompts.empty?
        puts "❌ No valid prompts found in file!"
        return
      end

      puts "✅ Loaded #{prompts.length} prompts!"

      prompts.each_with_index do |prompt, i|
        puts "\n#{i + 1}. 🎭 #{prompt[:title]}"
        puts "   📝 #{prompt[:description]}"
        puts "   🎨 Style: #{prompt[:style]}"
      end

      puts "\n🚀 Generate ALL #{prompts.length} images with #{@image_provider.upcase}? (y/n)"
      print "> "

      if gets.chomp.downcase.start_with?('y')
        puts "⏳ Generating images..."

        success_count = 0
        base_name = File.basename(prompt_file, '.prompt')

        # Store for potential export
        @last_generated_prompts = prompts

        prompts.each_with_index do |prompt, i|
          puts "\n🖼️  Creating image #{i + 1}/#{prompts.length}: #{prompt[:title]}"

          if generate_image(prompt, base_name, i + 1)
            success_count += 1
            puts "✅ Success! #{success_count}/#{prompts.length} complete"
          else
            puts "❌ Failed to generate image #{i + 1}"
          end

          sleep(1)
        end

        puts "\n🎉 FINISHED! Generated #{success_count}/#{prompts.length} images!"
        puts "📁 Check your #{@output_dir} folder! ✨"
      else
        puts "Cancelled image generation."
      end

    rescue => e
      puts "❌ Error importing prompts: #{e.message}"
    end

    puts "\n" + "🎨" * 30
    puts "Press ENTER to return to main menu..."
    gets
  end

  def parse_prompt_file(content)
    prompts = []

    # Try JSON format first
    begin
      json_data = JSON.parse(content)
      return json_data.map do |p|
        {
          title: p['title'] || 'Imported Prompt',
          description: p['description'] || 'Imported from file',
          style: p['style'] || 'artistic',
          prompt: p['prompt'] || 'Creative artwork'
        }
      end
    rescue JSON::ParserError
      # Fall back to text parsing
    end

    # Parse text format
    current_prompt = {}
    content.split("\n").each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('=', '-', '#')

      if line.match(/^\d+\.\s*(.+)$/)
        # Save previous prompt if complete
        if current_prompt[:title] && current_prompt[:prompt]
          prompts << current_prompt.dup
        end

        # Start new prompt
        current_prompt = { title: $1.strip }

      elsif line.start_with?('Description:', 'Desc:')
        current_prompt[:description] = line.split(':', 2)[1].strip

      elsif line.start_with?('Style:')
        current_prompt[:style] = line.split(':', 2)[1].strip

      elsif line.start_with?('Prompt:')
        current_prompt[:prompt] = line.split(':', 2)[1].strip.gsub(/^["']|["']$/, '')

      elsif current_prompt[:title] && !current_prompt[:prompt] && line.length > 20
        # Assume it's a prompt if it's long enough
        current_prompt[:prompt] = line.gsub(/^["']|["']$/, '')
        current_prompt[:style] ||= 'artistic'
        current_prompt[:description] ||= 'Imported prompt'
      end
    end

    # Don't forget the last prompt
    if current_prompt[:title] && current_prompt[:prompt]
      prompts << current_prompt
    end

    prompts
  end

  def export_last_prompts
    unless @last_generated_prompts && @last_generated_prompts.length > 0
      puts "\n❌ No prompts to export! Generate some prompts first, honey! 💅"
      return
    end

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    filename = "exported_prompts_#{timestamp}.prompt"
    filepath = File.join(@prompts_dir, filename)

    puts "\n📤 EXPORT PROMPTS"
    puts "=" * 50
    puts "Exporting #{@last_generated_prompts.length} prompts to: #{filename}"

    begin
      File.open(filepath, 'w') do |f|
        f.puts "# 🎨 Exported Image Prompts"
        f.puts "# Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        f.puts "# Provider: #{@image_provider.upcase}"
        f.puts "=" * 60
        f.puts

        # Export as JSON for easy re-import
        f.puts "# JSON Format (recommended for import):"
        f.puts JSON.pretty_generate(@last_generated_prompts)
        f.puts
        f.puts "=" * 60
        f.puts "# Text Format (human readable):"
        f.puts

        @last_generated_prompts.each_with_index do |prompt, i|
          f.puts "#{i + 1}. #{prompt[:title]}"
          f.puts "Description: #{prompt[:description]}"
          f.puts "Style: #{prompt[:style]}"
          f.puts "Prompt: \"#{prompt[:prompt]}\""
          f.puts
          f.puts "Command: ruby draw.rb # then import this file"
          f.puts "-" * 40
          f.puts
        end
      end

      puts "✅ Successfully exported to: #{filepath}"
      puts "💡 You can now import these prompts anytime with 'i' option!"

    rescue => e
      puts "❌ Export failed: #{e.message}"
    end

    puts "\n" + "🎨" * 30
    puts "Press ENTER to return to main menu..."
    gets
  end

  def show_help
    puts "\n🎨✨ CHAT-TO-IMAGE GENERATOR HELP ✨🎨"
    puts "=" * 60
    puts "This fabulous tool turns your chat conversations into ART!"
    puts ""
    puts "🎯 How it works:"
    puts "  1. Select a chat file from your ./chats folder"
    puts "  2. AI analyzes the conversation content"
    puts "  3. Generates 3 creative image prompts"
    puts "  4. Creates all images automatically"
    puts "  5. Returns to menu for more fun!"
    puts ""
    puts "📥📤 Import/Export Features:"
    puts "  i. Import prompts from .prompt files"
    puts "  e. Export last generated prompts"
    puts "  💡 Build your personal prompt library!"
    puts ""
    puts "🎨 AI Providers:"
    puts "  Automatic1111: FREE! (local install required) 🏠"
    puts "  Stability AI: ~$0.002/image (cloud premium) ☁️"
    puts "  Venice AI: ~$0.002/image (budget queen!) 💰"
    puts "  OpenAI: ~$0.040/image (luxury option!) 💎"
    puts ""
    puts "📁 Requirements:"
    puts "  • OpenAI API key (for prompt generation)"
    puts "  • Choose your image provider:"
    puts "    - Automatic1111: Local install + --api flag"
    puts "    - Stability AI: API key required"
    puts "    - Venice AI: API key required"
    puts "    - OpenAI: Uses same key as prompt generation"
    puts "  • Chat files in ./chats/*.txt"
    puts "  • Prompt files in ./prompts/*.prompt (for import)"
    puts ""
    puts "🔥 Automatic1111 Setup:"
    puts "  1. Install Automatic1111 WebUI"
    puts "  2. Run with: python launch.py --api"
    puts "  3. Keep it running while using this script!"
    puts ""
    puts "✨ Pro tip: Automatic1111 is FREE and gives amazing results!"
    puts "=" * 60
  end
end

# Check for help flag
if ARGV.include?('-h') || ARGV.include?('--help')
  puts "🎨 Chat-to-Image Generator"
  puts "Usage: ruby #{$0}"
  puts ""
  puts "Interactive tool that converts chat conversations into artwork!"
  puts "Place your chat files in ./chats/ and run this script."
  puts ""
  puts "Requirements:"
  puts "• OpenAI API key in 'openAI_api_key' file or OPENAI_API_KEY env var"
  puts "• Optional: Venice API key for cheaper image generation"
  exit 0
end

# Run the generator
begin
  generator = ChatToImageGenerator.new
  generator.run
rescue Interrupt
  puts "\n\n🛑 Goodbye, gorgeous! Thanks for using Chat-to-Image Generator! ✨"
rescue => e
  puts "❌ Oops! Something went wrong: #{e.message}"
  puts "💡 Make sure you have your API keys set up correctly!"
end