import React from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { Button, Input } from '../components/common';
import { Save, Volume2, MessageSquare } from 'lucide-react';
import { useSettingsStore } from '../store/settingsStore';

export const SettingsPage: React.FC = () => {
  const { apiProvider, voice, ttsEnabled, setApiProvider, setVoice, setTtsEnabled } = useSettingsStore();

  const [localApiProvider, setLocalApiProvider] = React.useState(apiProvider);
  const [localVoice, setLocalVoice] = React.useState(voice);
  const [localTtsEnabled, setLocalTtsEnabled] = React.useState(ttsEnabled);
  const [hasChanges, setHasChanges] = React.useState(false);

  React.useEffect(() => {
    const changed =
      localApiProvider !== apiProvider ||
      localVoice !== voice ||
      localTtsEnabled !== ttsEnabled;
    setHasChanges(changed);
  }, [localApiProvider, localVoice, localTtsEnabled, apiProvider, voice, ttsEnabled]);

  const handleSave = () => {
    setApiProvider(localApiProvider);
    setVoice(localVoice);
    setTtsEnabled(localTtsEnabled);
    setHasChanges(false);
  };

  const voices = [
    { value: 'alloy', label: 'Alloy' },
    { value: 'echo', label: 'Echo' },
    { value: 'fable', label: 'Fable' },
    { value: 'onyx', label: 'Onyx' },
    { value: 'nova', label: 'Nova' },
    { value: 'shimmer', label: 'Shimmer' },
  ];

  return (
    <AppLayout headerTitle="Settings">
      <div className="max-w-3xl space-y-6">
        {/* Chat Provider Settings */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <MessageSquare className="h-5 w-5 text-primary" />
            <h2 className="text-xl font-semibold text-text-primary">Chat Provider</h2>
          </div>
          <p className="text-sm text-text-secondary mb-4">
            Select the AI provider for chat completions. System prompts are sent to the selected provider.
          </p>
          <div className="space-y-3">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="radio"
                name="apiProvider"
                value="venice"
                checked={localApiProvider === 'venice'}
                onChange={(e) => setLocalApiProvider(e.target.value as 'venice' | 'openai')}
                className="w-4 h-4 text-primary focus:ring-primary"
              />
              <div>
                <span className="font-medium text-text-primary">Venice.ai (Default)</span>
                <p className="text-sm text-text-tertiary">Primary provider for chat completions</p>
              </div>
            </label>
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="radio"
                name="apiProvider"
                value="openai"
                checked={localApiProvider === 'openai'}
                onChange={(e) => setLocalApiProvider(e.target.value as 'venice' | 'openai')}
                className="w-4 h-4 text-primary focus:ring-primary"
              />
              <div>
                <span className="font-medium text-text-primary">OpenAI</span>
                <p className="text-sm text-text-tertiary">Alternative chat provider</p>
              </div>
            </label>
          </div>
        </div>

        {/* Text-to-Speech Settings */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <Volume2 className="h-5 w-5 text-primary" />
            <h2 className="text-xl font-semibold text-text-primary">Text-to-Speech</h2>
          </div>
          <p className="text-sm text-text-secondary mb-4">
            TTS always uses OpenAI, regardless of your chat provider selection.
          </p>
          
          <div className="space-y-4">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={localTtsEnabled}
                onChange={(e) => setLocalTtsEnabled(e.target.checked)}
                className="w-4 h-4 text-primary focus:ring-primary rounded"
              />
              <span className="font-medium text-text-primary">Enable Text-to-Speech</span>
            </label>

            {localTtsEnabled && (
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Voice Selection
                </label>
                <select
                  value={localVoice}
                  onChange={(e) => setLocalVoice(e.target.value)}
                  className="w-full px-4 py-2 border border-bg-muted rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all duration-default ease-in-out"
                >
                  {voices.map((v) => (
                    <option key={v.value} value={v.value}>
                      {v.label}
                    </option>
                  ))}
                </select>
                <p className="text-xs text-text-tertiary mt-1">
                  Selected voice will be used for all TTS generation
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Save Button */}
        {hasChanges && (
          <div className="flex justify-end">
            <Button onClick={handleSave} variant="primary">
              <Save className="h-4 w-4" />
              Save Settings
            </Button>
          </div>
        )}

        {/* Info Box */}
        <div className="bg-info/10 border-l-4 border-info p-4 rounded-lg">
          <p className="text-sm text-text-primary">
            <strong>Note:</strong> Settings are saved locally in your browser. These preferences will be used for all new chats.
          </p>
        </div>
      </div>
    </AppLayout>
  );
};

