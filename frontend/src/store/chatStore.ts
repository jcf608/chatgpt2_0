import { create } from 'zustand';
import type { Chat, Message } from '../api/types';
import { apiClient } from '../api/client';

interface ChatState {
  chats: Chat[];
  currentChat: Chat | null;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  fetchChats: () => Promise<void>;
  fetchChat: (id: string) => Promise<void>;
  createChat: (data: { title?: string; api_provider?: 'venice' | 'openai'; system_prompt_id?: string }) => Promise<Chat>;
  deleteChat: (id: string) => Promise<void>;
  sendMessage: (chatId: string, content: string) => Promise<void>;
  clearError: () => void;
  setCurrentChat: (chat: Chat | null) => void;
}

export const useChatStore = create<ChatState>((set, get) => ({
  chats: [],
  currentChat: null,
  isLoading: false,
  error: null,

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
    set({ isLoading: true, error: null });
    try {
      await apiClient.sendMessage(chatId, { content });
      // Refresh the current chat to get updated messages
      if (get().currentChat?.id === chatId) {
        await get().fetchChat(chatId);
      }
      // Refresh chats list to update metadata
      await get().fetchChats();
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to send message', isLoading: false });
    }
  },

  clearError: () => set({ error: null }),

  setCurrentChat: (chat: Chat | null) => set({ currentChat: chat }),
}));

