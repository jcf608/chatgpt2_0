require_relative 'base_api'
require_relative '../models/audio_output'
require_relative '../services/tts_service'
require_relative '../services/chat_service'

# AudioAPI - RESTful API for audio generation and retrieval
# Endpoints: POST /api/v1/chats/:id/audio, GET /api/v1/audio/:id

class AudioAPI < BaseAPI
  # List all audio files
  get '/api/v1/audio' do
    audio_files = AudioOutput.all
    success_response(audio_files.map(&:to_h))
  end

  # Generate audio from chat
  post '/api/v1/chats/:id/audio' do
    chat_service = ChatService.new(params[:id])
    chat = chat_service.load_chat

    # Get only assistant/AI responses (same as Save Chat)
    messages = chat_service.get_messages.select { |m| (m[:role] || m['role']) == 'assistant' }
    chat_content = messages.map { |m| m[:content] || m['content'] }.join("\n\n")

    # Generate audio using TTS service
    tts_service = TTSService.new(voice: chat.voice)
    audio_path = tts_service.process_chat_file(chat_content)

    unless audio_path && File.exist?(audio_path)
      error_response('Failed to generate audio', code: 'TTS_ERROR', status: 500)
      return
    end

    # Create audio output record
    audio_output = AudioOutput.new(
      chat_id: params[:id],
      description: "Audio for chat: #{chat.title}",
      file_path: File.basename(audio_path),
      file_size: File.size(audio_path)
    )
    audio_output.save

    success_response({
      audio_output: audio_output.to_h,
      file_url: "/api/v1/audio/#{audio_output.id}/file"
    }, status: 201)
  end

  # Get audio metadata
  get '/api/v1/audio/:id' do
    audio_output = AudioOutput.find_or_raise(params[:id])
    success_response(audio_output.to_h)
  end

  # Get audio file
  get '/api/v1/audio/:id/file' do
    audio_output = AudioOutput.find_or_raise(params[:id])
    file_path = audio_output.audio_file_path

    unless file_path && File.exist?(file_path)
      error_response('Audio file not found', code: 'NOT_FOUND', status: 404)
      return
    end

    content_type 'audio/mpeg'
    send_file file_path
  end
end

