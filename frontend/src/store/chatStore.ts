import { create } from 'zustand';
import type { Chat, Message } from '../api/types';
import { apiClient } from '../api/client';
import { useToastStore } from './toastStore';

interface ChatState {
  chats: Chat[];
  currentChat: Chat | null;
  isLoading: boolean;
  error: string | null;
  htmlErrorContent: string | null; // HTML content from Venice.ai errors
  
  // Actions
  fetchChats: () => Promise<void>;
  fetchChat: (id: string) => Promise<void>;
  createChat: (data: { title?: string; api_provider?: 'venice' | 'openai'; system_prompt_id?: string }) => Promise<Chat>;
  deleteChat: (id: string) => Promise<void>;
  sendMessage: (chatId: string, content: string) => Promise<void>;
  clearError: () => void;
  clearHtmlError: () => void;
  setCurrentChat: (chat: Chat | null) => void;
}

export const useChatStore = create<ChatState>((set, get) => ({
  chats: [],
  currentChat: null,
  isLoading: false,
  error: null,
  htmlErrorContent: null,

  fetchChats: async () => {
    set({ isLoading: true, error: null });
    try {
      const chats = await apiClient.getChats();
      set({ chats, isLoading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to fetch chats', isLoading: false });
    }
  },

  fetchChat: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      const chat = await apiClient.getChat(id);
      set({ currentChat: chat, isLoading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to fetch chat', isLoading: false });
    }
  },

  createChat: async (data) => {
    set({ isLoading: true, error: null });
    try {
      const chat = await apiClient.createChat(data);
      set((state) => ({
        chats: [chat, ...state.chats],
        currentChat: chat,
        isLoading: false,
      }));
      return chat;
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to create chat', isLoading: false });
      throw error;
    }
  },

  deleteChat: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      await apiClient.deleteChat(id);
      set((state) => ({
        chats: state.chats.filter((chat) => chat.id !== id),
        currentChat: state.currentChat?.id === id ? null : state.currentChat,
        isLoading: false,
      }));
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to delete chat', isLoading: false });
    }
  },

  sendMessage: async (chatId: string, content: string) => {
    set({ isLoading: true, error: null, htmlErrorContent: null });
    try {
      await apiClient.sendMessage(chatId, { content });
      // Refresh the current chat to get updated messages
      // Keep isLoading true throughout - fetchChat will temporarily set it, but we restore it
      if (get().currentChat?.id === chatId) {
        await get().fetchChat(chatId);
        // Ensure loading stays true until we're completely done
        set({ isLoading: true });
      }
      // Refresh chats list to update metadata
      await get().fetchChats();
      // Now set loading to false after everything completes
      set({ isLoading: false });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to send message';
      set({ error: errorMessage, isLoading: false });
      
      // Check if error contains HTML content (from Axios error response)
      let htmlContent: string | null = null;
      if (error && typeof error === 'object' && 'response' in error) {
        const axiosError = error as { response?: { data?: { error?: { details?: { html_content?: string } } } } };
        htmlContent = axiosError.response?.data?.error?.details?.html_content || null;
        if (htmlContent) {
          set({ htmlErrorContent: htmlContent });
        }
      }
      
      // Show toast notification for Venice.ai errors
      const toastStore = useToastStore.getState();
      if (errorMessage.includes('Venice.ai') || errorMessage.includes('AI_SERVICE_ERROR') || errorMessage.includes('AI_ERROR')) {
        toastStore.addToast(htmlContent ? 'Venice.ai returned an HTML error. Click to view details.' : errorMessage, 'error', 8000);
      } else {
        toastStore.addToast(errorMessage, 'error', 5000);
      }
    }
  },

  clearError: () => set({ error: null }),
  
  clearHtmlError: () => set({ htmlErrorContent: null }),

  setCurrentChat: (chat: Chat | null) => set({ currentChat: chat }),
}));

