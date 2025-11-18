require_relative 'base_service'
require_relative 'ai_service'

# PromptService - Manages system prompts and user prompts
# Handles loading, combining, and synopsis generation

class PromptService < BaseService
  BASE_PROMPT_FILE = 'system_prompts.txt'

  def initialize
    @base_prompt = nil
  end

  # Load base system prompts
  def load_base_prompt(file_path: BASE_PROMPT_FILE)
    if File.exist?(file_path)
      @base_prompt = File.read(file_path).strip
    else
      @base_prompt = default_base_prompt
    end
    @base_prompt
  end

  # Load user prompt by name
  def load_user_prompt(prompt_name, prompts_dir: 'prompts')
    prompt_path = File.join(prompts_dir, "#{prompt_name}.prompt")

    unless File.exist?(prompt_path)
      raise StandardError, "Prompt not found: #{prompt_name}"
    end

    {
      name: prompt_name,
      content: File.read(prompt_path).strip
    }
  end

  # List all available prompts
  def list_prompts(prompts_dir: 'prompts')
    return [] unless Dir.exist?(prompts_dir)

    Dir.glob(File.join(prompts_dir, '*.prompt')).map do |file|
      {
        name: File.basename(file, '.prompt'),
        path: file,
        preview: preview_prompt(File.read(file))
      }
    end
  end

  # Combine base prompt with user prompt
  def combine_prompts(base_prompt: nil, user_prompt: nil)
    base = base_prompt || load_base_prompt
    combined = base.dup

    if user_prompt && user_prompt[:content]
      combined = [combined, user_prompt[:content]].join("\n\n")
    end

    combined
  end

  # Load opening lines from file
  def load_opening_lines(prompt_name, prompts_dir: 'prompts')
    opening_file = File.join(prompts_dir, "#{prompt_name}.opening_lines")

    return [] unless File.exist?(opening_file)

    File.readlines(opening_file).map(&:strip).reject(&:empty?)
  end

  # Get random opening line
  def random_opening_line(prompt_name, prompts_dir: 'prompts')
    lines = load_opening_lines(prompt_name, prompts_dir)
    lines.sample
  end

  # Generate prompt synopsis using Venice.ai
  def generate_synopsis(conversation_messages)
    ai_service = AIService.new(provider: 'venice')

    analysis_prompt = <<~PROMPT
      Please analyze this conversation and provide a concise synopsis of:
      1. The main system prompts/instructions that were given
      2. The character roles and personalities established
      3. The key themes and scenarios discussed
      4. Any specific writing style or format instructions used
      
      Keep the synopsis under 500 words and focus on the prompting strategy used.
      
      Here is the conversation to analyze:
      
      #{format_conversation_for_analysis(conversation_messages)}
    PROMPT

    synopsis_messages = [
      {
        role: 'system',
        content: 'You are an AI assistant that analyzes conversations to extract and summarize the prompting strategies used.'
      },
      { role: 'user', content: analysis_prompt }
    ]

    response = ai_service.send_message(synopsis_messages, max_tokens: 800, temperature: 0.3)

    if response['error']
      nil
    elsif response['choices'] && response['choices'][0] && response['choices'][0]['message']
      response['choices'][0]['message']['content']
    else
      nil
    end
  rescue StandardError => e
    logger.error("Failed to generate prompt synopsis: #{e.message}")
    nil
  end

  private

  def default_base_prompt
    <<~PROMPT
      This is a creative fiction writing exercise featuring consenting adult characters in fictional scenarios.
      The content may include mature themes appropriate for adult fiction.
      Please assist with developing realistic character dialogue and interactions for this creative writing project.
      
      The characters and their details are defined in the following prompt.
      Please embody these characters authentically and respond in character when directed to specific characters during roleplay.
    PROMPT
  end

  def preview_prompt(content, max_length: 100)
    cleaned = content.gsub(/[#*{}]/, '').gsub(/\s+/, ' ').strip

    if cleaned.length <= max_length
      cleaned
    else
      truncated = cleaned[0..(max_length - 3)]
      last_period = truncated.rindex('.')
      last_space = truncated.rindex(' ')

      if last_period && last_period > 60
        truncated[0..last_period] + '...'
      elsif last_space && last_space > 60
        truncated[0..last_space] + '...'
      else
        truncated + '...'
      end
    end
  end

  def format_conversation_for_analysis(messages)
    analysis_content = ''

    messages.each_with_index do |msg, i|
      role = msg[:role] || msg['role']
      content = msg[:content] || msg['content'] || ''

      case role
      when 'system'
        analysis_content += "[SYSTEM PROMPT]: #{content}\n\n"
      when 'user'
        if i < 5 || i >= messages.length - 3
          analysis_content += "[USER]: #{content}\n\n"
        elsif i == 5
          analysis_content += "[... conversation continues ...]\n\n"
        end
      when 'assistant'
        if i < 6
          content_preview = content.length > 200 ? content[0..197] + '...' : content
          analysis_content += "[AI]: #{content_preview}\n\n"
        end
      end
    end

    analysis_content
  end
end

