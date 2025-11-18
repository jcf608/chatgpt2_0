import { create } from 'zustand';
import type { Prompt } from '../api/types';
import { apiClient } from '../api/client';

interface PromptState {
  prompts: Prompt[];
  selectedPrompt: Prompt | null;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  fetchPrompts: () => Promise<void>;
  fetchPrompt: (id: string) => Promise<void>;
  createPrompt: (data: { name: string; content: string }) => Promise<Prompt>;
  updatePrompt: (id: string, data: { name?: string; content?: string }) => Promise<void>;
  deletePrompt: (id: string) => Promise<void>;
  setSelectedPrompt: (prompt: Prompt | null) => void;
  clearError: () => void;
}

export const usePromptStore = create<PromptState>((set, get) => ({
  prompts: [],
  selectedPrompt: null,
  isLoading: false,
  error: null,

  fetchPrompts: async () => {
    set({ isLoading: true, error: null });
    try {
      const prompts = await apiClient.getPrompts();
      set({ prompts, isLoading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to fetch prompts', isLoading: false });
    }
  },

  fetchPrompt: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      const prompt = await apiClient.getPrompt(id);
      set({ selectedPrompt: prompt, isLoading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to fetch prompt', isLoading: false });
    }
  },

  createPrompt: async (data) => {
    set({ isLoading: true, error: null });
    try {
      const prompt = await apiClient.createPrompt(data);
      set((state) => ({
        prompts: [prompt, ...state.prompts],
        isLoading: false,
      }));
      return prompt;
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to create prompt', isLoading: false });
      throw error;
    }
  },

  updatePrompt: async (id: string, data) => {
    set({ isLoading: true, error: null });
    try {
      const prompt = await apiClient.updatePrompt(id, data);
      set((state) => ({
        prompts: state.prompts.map((p) => (p.id === id ? prompt : p)),
        selectedPrompt: state.selectedPrompt?.id === id ? prompt : state.selectedPrompt,
        isLoading: false,
      }));
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to update prompt', isLoading: false });
    }
  },

  deletePrompt: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      await apiClient.deletePrompt(id);
      set((state) => ({
        prompts: state.prompts.filter((p) => p.id !== id),
        selectedPrompt: state.selectedPrompt?.id === id ? null : state.selectedPrompt,
        isLoading: false,
      }));
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to delete prompt', isLoading: false });
    }
  },

  setSelectedPrompt: (prompt: Prompt | null) => set({ selectedPrompt: prompt }),

  clearError: () => set({ error: null }),
}));

