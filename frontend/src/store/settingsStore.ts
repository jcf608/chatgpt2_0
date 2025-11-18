import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface SettingsState {
  apiProvider: 'venice' | 'openai';
  voice: string;
  ttsEnabled: boolean;
  selectedPromptId: string | null;
  
  // Actions
  setApiProvider: (provider: 'venice' | 'openai') => void;
  setVoice: (voice: string) => void;
  setTtsEnabled: (enabled: boolean) => void;
  setSelectedPromptId: (promptId: string | null) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      apiProvider: 'venice',
      voice: 'echo',
      ttsEnabled: true,
      selectedPromptId: null,

      setApiProvider: (provider) => set({ apiProvider: provider }),
      setVoice: (voice) => set({ voice }),
      setTtsEnabled: (enabled) => set({ ttsEnabled: enabled }),
      setSelectedPromptId: (promptId) => set({ selectedPromptId: promptId }),
    }),
    {
      name: 'chatgpt-settings',
      storage: createJSONStorage(() => localStorage),
    }
  )
);

