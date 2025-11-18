// API Types for ChatGPT v2.0

export interface Chat {
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
  system_prompt_id?: string;
  api_provider: 'venice' | 'openai';
  voice?: string;
  messages: Message[];
  metadata?: {
    word_count?: number;
    message_count?: number;
    audio_file?: string;
  };
}

export interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  sequence_number: number;
  created_at: string;
}

export interface Prompt {
  id: string;
  name: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface AudioOutput {
  id: string;
  chat_id: string;
  file_path: string;
  created_at: string;
  metadata?: {
    duration?: number;
    voice?: string;
  };
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    message: string;
    code?: string;
    details?: Record<string, unknown>;
  };
  timestamp: string;
}

export interface CreateChatRequest {
  title?: string;
  api_provider?: 'venice' | 'openai';
  system_prompt_id?: string;
  voice?: string;
}

export interface SendMessageRequest {
  content: string;
}

export interface ExtendDialogueRequest {
  target_words: number;
  progress_callback?: (segment: number, words: number, total: number, target: number) => void;
}

export interface ContinueConversationRequest {
  additional_words: number;
  user_prompt?: string;
}

