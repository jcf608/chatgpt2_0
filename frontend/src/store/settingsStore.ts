import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface SettingsState {
  apiProvider: 'venice' | 'openai';
  voice: string;
  ttsEnabled: boolean;
  
  // Actions
  setApiProvider: (provider: 'venice' | 'openai') => void;
  setVoice: (voice: string) => void;
  setTtsEnabled: (enabled: boolean) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      apiProvider: 'venice',
      voice: 'echo',
      ttsEnabled: true,

      setApiProvider: (provider) => set({ apiProvider: provider }),
      setVoice: (voice) => set({ voice }),
      setTtsEnabled: (enabled) => set({ ttsEnabled: enabled }),
    }),
    {
      name: 'chatgpt-settings',
      storage: createJSONStorage(() => localStorage),
    }
  )
);

