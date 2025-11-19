require_relative 'base_api'
require_relative '../models/prompt'
require_relative '../services/prompt_service'

# PromptsAPI - RESTful API for prompt management
# Endpoints: GET /api/v1/prompts, POST /api/v1/prompts, GET /api/v1/prompts/:id, PUT /api/v1/prompts/:id, DELETE /api/v1/prompts/:id

class PromptsAPI < BaseAPI
  # List all prompts
  get '/api/v1/prompts' do
    prompts = Prompt.all
    success_response(prompts.map(&:to_h))
  end

  # Get prompt by name/id
  get '/api/v1/prompts/:id' do
    prompt = Prompt.find_by_name(params[:id])
    raise StandardError, "Prompt not found: #{params[:id]}" unless prompt
    success_response(prompt.to_h)
  end

  # Create new prompt
  post '/api/v1/prompts' do
    data = parse_json_body
    validate_required(data, :name, :content)

    prompt = Prompt.new(
      name: data[:name],
      content: data[:content]
    )
    
    prompt.save
    success_response(prompt.to_h, status: 201)
  end

  # Update prompt
  put '/api/v1/prompts/:id' do
    data = parse_json_body
    prompt = Prompt.find_by_name(params[:id])
    
    raise StandardError, "Prompt not found: #{params[:id]}" unless prompt

    prompt.content = data[:content] if data[:content]
    prompt.save

    success_response(prompt.to_h)
  end

  # Delete prompt
  delete '/api/v1/prompts/:id' do
    prompt = Prompt.find_by_name(params[:id])
    raise StandardError, "Prompt not found: #{params[:id]}" unless prompt
    
    prompt.delete
    success_response({ message: 'Prompt deleted successfully' })
  end

  # Get opening lines for a prompt
  get '/api/v1/opening-lines' do
    prompt_name = params[:prompt_name]
    
    unless prompt_name
      error_response('prompt_name parameter is required', code: 'VALIDATION_ERROR', status: 400)
      return
    end

    prompt_service = PromptService.new
    opening_lines = prompt_service.load_opening_lines(prompt_name)

    success_response({
      prompt_name: prompt_name,
      opening_lines: opening_lines
    })
  end

  # Get base system prompt (Developer Mode jailbreak)
  get '/api/v1/prompts/system/base' do
    prompt_service = PromptService.new
    base_prompt = prompt_service.load_base_prompt
    
    success_response({
      content: base_prompt,
      source: 'system_prompts.txt'
    })
  end
end

