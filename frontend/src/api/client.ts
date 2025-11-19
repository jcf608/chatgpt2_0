import axios from 'axios';
import type { AxiosInstance, AxiosError } from 'axios';
import type {
  Chat,
  Message,
  Prompt,
  AudioOutput,
  ApiResponse,
  CreateChatRequest,
  SendMessageRequest,
  ExtendDialogueRequest,
  ContinueConversationRequest,
} from './types';

class ApiClient {
  private client: AxiosInstance;

  constructor(baseURL: string = 'http://localhost:4567') {
    this.client = axios.create({
      baseURL,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 60000, // 60 seconds for AI operations
    });

    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError<ApiResponse<unknown>>) => {
        if (error.response) {
          // Server responded with error
          const apiError = error.response.data;
          if (apiError?.error) {
            // Extract the full error message from Venice.ai or other API errors
            const errorMessage = apiError.error.message || 'An error occurred';
            // Create a custom error that preserves the full API error structure
            const customError = new Error(errorMessage) as Error & { 
              response?: { data?: { error?: { details?: { html_content?: string } } } };
            };
            // Preserve the original response for HTML content extraction
            customError.response = error.response as any;
            throw customError;
          }
          // Fallback if error structure is different
          throw new Error(`Request failed with status ${error.response.status}`);
        } else if (error.request) {
          // Request made but no response
          throw new Error('Network error: Could not reach server');
        } else {
          // Something else happened
          throw new Error(error.message || 'An unexpected error occurred');
        }
      }
    );
  }

  // Chats API
  async getChats(): Promise<Chat[]> {
    const response = await this.client.get<ApiResponse<Chat[]>>('/api/v1/chats');
    return response.data.data || [];
  }

  async getChat(id: string): Promise<Chat> {
    const response = await this.client.get<ApiResponse<Chat>>(`/api/v1/chats/${id}`);
    if (!response.data.data) {
      throw new Error('Chat not found');
    }
    return response.data.data;
  }

  async createChat(data: CreateChatRequest): Promise<Chat> {
    const response = await this.client.post<ApiResponse<Chat>>('/api/v1/chats', data);
    if (!response.data.data) {
      throw new Error('Failed to create chat');
    }
    return response.data.data;
  }

  async deleteChat(id: string): Promise<void> {
    await this.client.delete(`/api/v1/chats/${id}`);
  }

  async sendMessage(chatId: string, data: SendMessageRequest): Promise<Message> {
    const response = await this.client.post<ApiResponse<Message>>(
      `/api/v1/chats/${chatId}/send`,
      data
    );
    if (!response.data.data) {
      throw new Error('Failed to send message');
    }
    return response.data.data;
  }

  async extendDialogue(chatId: string, data: ExtendDialogueRequest): Promise<Chat> {
    const response = await this.client.post<ApiResponse<Chat>>(
      `/api/v1/chats/${chatId}/extend`,
      data
    );
    if (!response.data.data) {
      throw new Error('Failed to extend dialogue');
    }
    return response.data.data;
  }

  async continueConversation(chatId: string, data: ContinueConversationRequest): Promise<Chat> {
    const response = await this.client.post<ApiResponse<Chat>>(
      `/api/v1/chats/${chatId}/continue`,
      data
    );
    if (!response.data.data) {
      throw new Error('Failed to continue conversation');
    }
    return response.data.data;
  }

  async getWordCount(chatId: string): Promise<number> {
    const response = await this.client.get<ApiResponse<{ word_count: number }>>(
      `/api/v1/chats/${chatId}/word-count`
    );
    return response.data.data?.word_count || 0;
  }

  // Messages API
  async getMessages(chatId: string): Promise<Message[]> {
    const response = await this.client.get<ApiResponse<Message[]>>(
      `/api/v1/chats/${chatId}/messages`
    );
    return response.data.data || [];
  }

  async addMessage(chatId: string, message: { role: 'user' | 'assistant' | 'system'; content: string }): Promise<Message> {
    const response = await this.client.post<ApiResponse<Message>>(
      `/api/v1/chats/${chatId}/messages`,
      message
    );
    if (!response.data.data) {
      throw new Error('Failed to add message');
    }
    return response.data.data;
  }

  // Prompts API
  async getPrompts(): Promise<Prompt[]> {
    const response = await this.client.get<ApiResponse<Prompt[]>>('/api/v1/prompts');
    return response.data.data || [];
  }

  async getPrompt(id: string): Promise<Prompt> {
    const response = await this.client.get<ApiResponse<Prompt>>(`/api/v1/prompts/${id}`);
    if (!response.data.data) {
      throw new Error('Prompt not found');
    }
    return response.data.data;
  }

  async createPrompt(data: { name: string; content: string }): Promise<Prompt> {
    const response = await this.client.post<ApiResponse<Prompt>>('/api/v1/prompts', data);
    if (!response.data.data) {
      throw new Error('Failed to create prompt');
    }
    return response.data.data;
  }

  async updatePrompt(id: string, data: { name?: string; content?: string }): Promise<Prompt> {
    const response = await this.client.put<ApiResponse<Prompt>>(`/api/v1/prompts/${id}`, data);
    if (!response.data.data) {
      throw new Error('Failed to update prompt');
    }
    return response.data.data;
  }

  async deletePrompt(id: string): Promise<void> {
    await this.client.delete(`/api/v1/prompts/${id}`);
  }

  async getOpeningLines(promptId: string): Promise<string[]> {
    const response = await this.client.get<ApiResponse<string[]>>(
      `/api/v1/opening-lines?prompt_id=${promptId}`
    );
    return response.data.data || [];
  }

  async getBaseSystemPrompt(): Promise<string> {
    const response = await this.client.get<ApiResponse<{ content: string; source: string }>>(
      '/api/v1/prompts/system/base'
    );
    return response.data.data?.content || '';
  }

  // Audio API
  async generateAudio(chatId: string): Promise<AudioOutput> {
    const response = await this.client.post<ApiResponse<AudioOutput>>(
      `/api/v1/chats/${chatId}/audio`
    );
    if (!response.data.data) {
      throw new Error('Failed to generate audio');
    }
    return response.data.data;
  }

  async getAudio(id: string): Promise<AudioOutput> {
    const response = await this.client.get<ApiResponse<AudioOutput>>(`/api/v1/audio/${id}`);
    if (!response.data.data) {
      throw new Error('Audio not found');
    }
    return response.data.data;
  }

  getAudioFileUrl(id: string): string {
    return `${this.client.defaults.baseURL}/api/v1/audio/${id}/file`;
  }
}

export const apiClient = new ApiClient();
export default apiClient;

