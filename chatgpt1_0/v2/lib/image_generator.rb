require 'fileutils'
require_relative 'openai_client'
require_relative 'venice_client'

module V2
  # Image generation service
  class ImageGenerator
    PROVIDERS = ['openai', 'venice']
    
    attr_reader :provider, :openai_client, :venice_client
    
    def initialize(provider: 'openai', openai_api_key: nil, venice_api_key: nil)
      @provider = provider
      @openai_client = OpenAIClient.new(openai_api_key)
      @venice_client = VeniceClient.new(venice_api_key)
    end
    
    # Switch the active provider
    def toggle_provider(provider)
      if PROVIDERS.include?(provider)
        @provider = provider
        puts "Switched to #{provider} provider"
        true
      else
        puts "Invalid provider: #{provider}. Available providers: #{PROVIDERS.join(', ')}"
        false
      end
    end
    
    # Generate image prompts from chat content
    def generate_image_prompts(chat_content, chat_name)
      # Clean the chat content
      cleaned_content = clean_chat_content(chat_content)
      
      # Extract key themes and concepts
      themes = extract_themes(cleaned_content)
      
      # Generate prompts based on the themes
      prompts = []
      
      # Use the current provider to generate prompts
      client = current_client
      
      # Create a system message that instructs the AI to generate image prompts
      system_message = {
        "role" => "system",
        "content" => "You are a creative prompt engineer for image generation. Create 3 detailed, vivid image prompts based on the themes and content provided. Each prompt should be descriptive, evocative, and suitable for image generation. Focus on visual elements, mood, lighting, and composition. Give each prompt a short, descriptive title."
      }
      
      # Create a user message with the themes and chat content
      user_message = {
        "role" => "user",
        "content" => "Generate 3 image prompts based on these themes: #{themes.join(', ')}. The prompts should capture the essence of this conversation: #{cleaned_content[0..1000]}..."
      }
      
      # Make the API request
      messages = [system_message, user_message]
      
      begin
        response = client.chat_completion(messages)
        
        # Parse the response to extract the prompts
        if response['choices'] && response['choices'][0] && response['choices'][0]['message']
          content = response['choices'][0]['message']['content']
          
          # Extract the prompts from the content
          content.split(/\d+\./).drop(1).each do |prompt_text|
            # Extract title and description
            if prompt_text =~ /(.+?):\s*(.+)/m
              title = $1.strip
              description = $2.strip
              
              prompts << {
                title: title,
                description: description,
                chat_name: chat_name
              }
            end
          end
        end
      rescue => e
        puts "Error generating prompts: #{e.message}"
        # Create fallback prompts if API request fails
        prompts = create_fallback_prompts(chat_name)
      end
      
      # Ensure we have at least 3 prompts
      if prompts.size < 3
        additional_prompts = create_fallback_prompts(chat_name)
        prompts += additional_prompts[0..(2 - prompts.size)]
      end
      
      prompts[0..2] # Return at most 3 prompts
    end
    
    # Generate an image from a prompt
    def generate_image(prompt_data, chat_name, image_number)
      # Create illustrations directory if it doesn't exist
      FileUtils.mkdir_p('illustrations') unless Dir.exist?('illustrations')
      
      # Generate a filename based on the chat name and prompt title
      safe_chat_name = sanitize_filename(chat_name)
      safe_title = sanitize_filename(prompt_data[:title].downcase.gsub(/\s+/, '_'))
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      
      filename = "illustrations/#{@provider}_#{safe_chat_name}_#{image_number}_#{safe_title}_#{timestamp}.png"
      
      # Generate the image using the current provider
      case @provider
      when 'openai'
        generate_with_openai(prompt_data, filename)
      when 'venice'
        generate_with_venice(prompt_data, filename)
      else
        puts "Unknown provider: #{@provider}"
        return nil
      end
      
      filename
    end
    
    # Generate an image using OpenAI
    def generate_with_openai(prompt_data, filename)
      puts "Generating image with OpenAI: #{prompt_data[:title]}"
      
      begin
        response = @openai_client.generate_image(prompt_data[:description])
        
        if response['data'] && response['data'][0] && response['data'][0]['url']
          image_url = response['data'][0]['url']
          
          # Download the image
          uri = URI(image_url)
          image_data = Net::HTTP.get(uri)
          
          # Save the image
          File.open(filename, 'wb') { |file| file.write(image_data) }
          puts "Image saved to: #{filename}"
          return filename
        else
          puts "Error: No image URL in response"
          return nil
        end
      rescue => e
        puts "Error generating image with OpenAI: #{e.message}"
        return nil
      end
    end
    
    # Generate an image using Venice
    def generate_with_venice(prompt_data, filename)
      puts "Generating image with Venice: #{prompt_data[:title]}"
      
      begin
        response = @venice_client.generate_image(prompt_data[:description])
        
        if response['data'] && response['data'][0] && response['data'][0]['url']
          image_url = response['data'][0]['url']
          
          # Download the image
          uri = URI(image_url)
          image_data = Net::HTTP.get(uri)
          
          # Save the image
          File.open(filename, 'wb') { |file| file.write(image_data) }
          puts "Image saved to: #{filename}"
          return filename
        else
          puts "Error: No image URL in response"
          return nil
        end
      rescue => e
        puts "Error generating image with Venice: #{e.message}"
        return nil
      end
    end
    
    # Process a chat file and generate images
    def process_chat_file(file_path)
      unless File.exist?(file_path)
        puts "Error: File not found: #{file_path}"
        return []
      end
      
      content = File.read(file_path)
      chat_name = File.basename(file_path, '.*')
      
      # Generate prompts from the chat content
      prompts = generate_image_prompts(content, chat_name)
      
      # Generate images for each prompt
      images = []
      prompts.each_with_index do |prompt, index|
        image_path = generate_image(prompt, chat_name, index + 1)
        images << image_path if image_path
      end
      
      images
    end
    
    private
    
    # Get the current client based on the provider
    def current_client
      case @provider
      when 'openai'
        @openai_client
      when 'venice'
        @venice_client
      else
        @openai_client # Default to OpenAI
      end
    end
    
    # Clean chat content by removing system messages and formatting
    def clean_chat_content(content)
      cleaned = ""
      
      content.each_line do |line|
        # Skip system messages and empty lines
        next if line.include?("🤖 System:") || line.strip.empty?
        
        # Remove emoji and role prefixes
        cleaned_line = line.gsub(/^(🧑|👤|👩‍💻|🧔) (User|You):/, "User:").gsub(/^(🤖|🔮|💬) (Assistant|AI|ChatGPT):/, "Assistant:")
        
        cleaned += cleaned_line
      end
      
      cleaned
    end
    
    # Extract themes from chat content
    def extract_themes(content)
      # Simple extraction of frequent words
      words = content.downcase.gsub(/[^\w\s]/, '').split
      
      # Remove common words
      stop_words = ['the', 'and', 'a', 'to', 'of', 'in', 'is', 'it', 'you', 'that', 'was', 'for', 'on', 'are', 'with', 'as', 'I', 'his', 'they', 'be', 'at', 'one', 'have', 'this', 'from', 'by', 'hot', 'word', 'but', 'what', 'some', 'can', 'out', 'other', 'were', 'all', 'there', 'when', 'up', 'use', 'your', 'how', 'said', 'an', 'each', 'she', 'which', 'do', 'their', 'time', 'if', 'will', 'way', 'about', 'many', 'then', 'them', 'would', 'write', 'like', 'so', 'these', 'her', 'long', 'make', 'thing', 'see', 'him', 'two', 'has', 'look', 'more', 'day', 'could', 'go', 'come', 'did', 'number', 'sound', 'no', 'most', 'people', 'my', 'over', 'know', 'water', 'than', 'call', 'first', 'who', 'may', 'down', 'side', 'been', 'now', 'find', 'any', 'new', 'work', 'part', 'take', 'get', 'place', 'made', 'live', 'where', 'after', 'back', 'little', 'only', 'round', 'man', 'year', 'came', 'show', 'every', 'good', 'me', 'give', 'our', 'under', 'name', 'very', 'through', 'just', 'form', 'sentence', 'great', 'think', 'say', 'help', 'low', 'line', 'differ', 'turn', 'cause', 'much', 'mean', 'before', 'move', 'right', 'boy', 'old', 'too', 'same', 'tell', 'does', 'set', 'three', 'want', 'air', 'well', 'also', 'play', 'small', 'end', 'put', 'home', 'read', 'hand', 'port', 'large', 'spell', 'add', 'even', 'land', 'here', 'must', 'big', 'high', 'such', 'follow', 'act', 'why', 'ask', 'men', 'change', 'went', 'light', 'kind', 'off', 'need', 'house', 'picture', 'try', 'us', 'again', 'animal', 'point', 'mother', 'world', 'near', 'build', 'self', 'earth', 'father']
      
      filtered_words = words.reject { |word| stop_words.include?(word) || word.length < 4 }
      
      # Count word frequencies
      word_counts = Hash.new(0)
      filtered_words.each { |word| word_counts[word] += 1 }
      
      # Get the top 10 most frequent words
      top_words = word_counts.sort_by { |_, count| -count }.take(10).map { |word, _| word }
      
      # Add some default themes if we don't have enough
      if top_words.size < 5
        default_themes = ['conversation', 'interaction', 'communication', 'dialogue', 'exchange']
        top_words += default_themes[0..(4 - top_words.size)]
      end
      
      top_words
    end
    
    # Create fallback prompts if API request fails
    def create_fallback_prompts(chat_name)
      [
        {
          title: "Conversation Visualization",
          description: "A visual representation of a deep conversation between two people, with swirling colors representing their exchange of ideas and emotions. The image should have warm tones and a dreamlike quality.",
          chat_name: chat_name
        },
        {
          title: "Digital Connection",
          description: "Two silhouettes facing each other with a glowing digital interface between them, representing online communication. The background should have a tech-inspired aesthetic with code-like patterns and a blue-purple color scheme.",
          chat_name: chat_name
        },
        {
          title: "Emotional Exchange",
          description: "An abstract representation of emotional exchange, with vibrant colors flowing between two abstract human forms. The image should convey depth of feeling and connection through color and form.",
          chat_name: chat_name
        }
      ]
    end
    
    # Sanitize a filename by removing invalid characters
    def sanitize_filename(text)
      text.gsub(/[^0-9A-Za-z_\-]/, '_')[0..50]
    end
  end
end