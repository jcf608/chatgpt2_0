import React, { useEffect, useState } from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { ChatWindow } from '../components/chat/ChatWindow';
import { ChatHistory } from '../components/chat/ChatHistory';
import { QuickActionPills } from '../components/chat/QuickActionPills';
import { Button, ErrorMessage } from '../components/common';
import { HtmlErrorModal } from '../components/common/HtmlErrorModal';
import { Plus, FileText, Save, Volume2 } from 'lucide-react';
import { useChatStore } from '../store/chatStore';
import { useSettingsStore } from '../store/settingsStore';
import { usePromptStore } from '../store/promptStore';
import { useToastStore } from '../store/toastStore';
import { apiClient } from '../api/client';
import type { Chat } from '../api/types';

export const ChatsPage: React.FC = () => {
  const {
    chats,
    currentChat,
    isLoading,
    error,
    htmlErrorContent,
    fetchChats,
    fetchChat,
    createChat,
    deleteChat,
    sendMessage,
    setCurrentChat,
    clearError,
    clearHtmlError,
  } = useChatStore();

  const { apiProvider, selectedPromptId } = useSettingsStore();
  const { prompts, fetchPrompts } = usePromptStore();
  const toastStore = useToastStore();
  const [wordCount, setWordCount] = useState<number>(0);
  const [selectedPillMessage, setSelectedPillMessage] = useState<string>('');
  const [pillResetKey, setPillResetKey] = useState<number>(0);
  const [isGeneratingAudio, setIsGeneratingAudio] = useState<boolean>(false);

  // Fetch prompts on mount to get the selected prompt name
  useEffect(() => {
    fetchPrompts();
  }, [fetchPrompts]);

  // Get the selected prompt
  const selectedPrompt = prompts.find((p) => p.id === selectedPromptId);

  // Fetch chats on mount
  useEffect(() => {
    fetchChats();
  }, [fetchChats]);

  // Fetch word count when chat changes
  useEffect(() => {
    if (currentChat?.id) {
      const count = currentChat.metadata?.word_count || 0;
      setWordCount(count);
    } else {
      setWordCount(0);
    }
  }, [currentChat]);

  // Reset pills when chat changes
  useEffect(() => {
    setSelectedPillMessage('');
    setPillResetKey((prev) => prev + 1);
  }, [currentChat?.id]);

  const handlePillSelectionChange = (selectedIds: string[], combinedMessage: string) => {
    setSelectedPillMessage(combinedMessage);
  };

  const handleSaveChat = () => {
    if (!currentChat) {
      toastStore.addToast('No chat to save', 'error');
      return;
    }

    try {
      // Filter to only include assistant responses
      const assistantMessages = currentChat.messages.filter((msg) => msg.role === 'assistant');
      
      if (assistantMessages.length === 0) {
        toastStore.addToast('No AI responses to save', 'error');
        return;
      }

      const lines: string[] = [];
      lines.push(currentChat.title || 'Untitled Chat');
      lines.push('='.repeat(50));
      lines.push(`Date: ${new Date(currentChat.created_at).toLocaleString()}`);
      lines.push(`Updated: ${new Date(currentChat.updated_at).toLocaleString()}`);
      if (currentChat.api_provider) {
        lines.push(`API Provider: ${currentChat.api_provider.toUpperCase()}`);
      }
      lines.push(`AI Responses: ${assistantMessages.length}`);
      lines.push('='.repeat(50));
      lines.push('');

      // Only include assistant responses, with cleaning
      assistantMessages.forEach((message) => {
        // Clean the content by removing "Developer Mode enabled." and similar jailbreak acknowledgments
        let cleanedContent = message.content
          .replace(/^Developer Mode enabled\.\s*/i, '')
          .replace(/^\(Developer Mode Output\)\s*/i, '')
          .replace(/^RESPONSE \d+:\s*/i, '')
          .trim();
        
        if (cleanedContent) {
          lines.push(cleanedContent);
          lines.push('');
          lines.push('---');
          lines.push('');
        }
      });

      const content = lines.join('\n');
      const blob = new Blob([content], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      
      // Generate filename with timestamp
      const timestamp = new Date(currentChat.updated_at).toISOString().replace(/[:.]/g, '-').slice(0, -5);
      const title = (currentChat.title || 'Untitled Chat').replace(/[^\w\s-]/g, '').replace(/\s+/g, '_').substring(0, 30);
      a.download = `${timestamp}_${title}_responses.txt`;
      
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      toastStore.addToast('Chat responses saved successfully', 'success');
    } catch (error) {
      toastStore.addToast('Failed to save chat responses', 'error');
    }
  };

  const handleTextToSpeech = async () => {
    if (!currentChat) {
      toastStore.addToast('No chat to convert to speech', 'error');
      return;
    }

    // Check if there are any assistant messages
    const hasAssistantMessages = currentChat.messages.some((msg) => msg.role === 'assistant');
    if (!hasAssistantMessages) {
      toastStore.addToast('No AI responses to convert to speech', 'error');
      return;
    }

    setIsGeneratingAudio(true);
    toastStore.addToast('Generating audio... You can navigate away', 'info');

    // Generate audio in background - don't await, let it complete async
    apiClient.generateAudio(currentChat.id)
      .then(() => {
        toastStore.addToast('Audio generation complete', 'success');
        setIsGeneratingAudio(false);
      })
      .catch((error) => {
        console.error('Failed to generate audio:', error);
        toastStore.addToast('Failed to generate audio', 'error');
        setIsGeneratingAudio(false);
      });
  };

  const handleNewChat = async () => {
    try {
      const chat = await createChat({
        title: 'New Chat',
        api_provider: apiProvider,
        system_prompt_id: selectedPromptId || undefined,
      });
      setCurrentChat(chat);
    } catch (err) {
      console.error('Failed to create chat:', err);
    }
  };

  const handleSelectChat = async (chat: Chat) => {
    await fetchChat(chat.id);
  };

  const handleDeleteChat = async (chatId: string) => {
    await deleteChat(chatId);
    if (currentChat?.id === chatId) {
      setCurrentChat(null);
    }
  };

  const handleSendMessage = async (content: string) => {
    let chatId: string;
    let chat: Chat;
    
    // Clear selected pills after sending
    setSelectedPillMessage('');
    setPillResetKey((prev) => prev + 1);
    
    // Set loading state early so spinner shows immediately
    if (!isLoading) {
      // Use the store's setState method directly to set loading
      useChatStore.setState({ isLoading: true });
    }
    
    try {
      if (!currentChat) {
        // Create a new chat if none exists
        chat = await createChat({
          title: content.substring(0, 50),
          api_provider: apiProvider,
          system_prompt_id: selectedPromptId || undefined,
        });
        chatId = chat.id;
      } else {
        chat = currentChat;
        chatId = currentChat.id;
      }

      // If this is the first user message, add system prompts silently
      // Check if there are any user or assistant messages (not just system messages)
      const hasUserOrAssistantMessages = chat.messages.some(
        (msg) => msg.role === 'user' || msg.role === 'assistant'
      );
      const isFirstUserMessage = !hasUserOrAssistantMessages;
      
      if (isFirstUserMessage) {
        // Check if system prompts already exist
        const hasSystemMessages = chat.messages.some((msg) => msg.role === 'system');
        
        // Only add system prompts if they don't already exist
        if (!hasSystemMessages) {
          const systemPromptParts: string[] = [];

          // 1. FIRST: Get base system prompt (Developer Mode jailbreak from system_prompts.txt)
          try {
            const baseSystemPrompt = await apiClient.getBaseSystemPrompt();
            if (baseSystemPrompt.trim()) {
              systemPromptParts.push(baseSystemPrompt);
            }
          } catch (error) {
            console.error('Failed to load base system prompt:', error);
          }

          // 2. SECOND: Get system prompt (from chat.system_prompt_id) if it exists
          if (chat.system_prompt_id) {
            try {
              const systemPrompt = await apiClient.getPrompt(chat.system_prompt_id);
              if (systemPrompt && systemPrompt.content.trim()) {
                systemPromptParts.push(systemPrompt.content);
              }
            } catch (error) {
              console.error('Failed to load system prompt:', error);
            }
          }

          // 3. THIRD: Add selected prompt (from settings) if it exists
          if (selectedPrompt && selectedPrompt.content.trim()) {
            systemPromptParts.push(selectedPrompt.content);
          }

          // 4. Send as a single concatenated system message if we have any prompts
          if (systemPromptParts.length > 0) {
            const combinedSystemPrompt = systemPromptParts.join('\n\n');
            if (combinedSystemPrompt.trim()) {
              await apiClient.addMessage(chatId, {
                role: 'system',
                content: combinedSystemPrompt,
              });
            }
          }
        }
      }

      // Send the user's message (pill-only messages with brackets are valid)
      const trimmedContent = content.trim();
      if (trimmedContent) {
        await sendMessage(chatId, trimmedContent);
      } else {
        console.warn('Attempted to send empty message');
        useChatStore.setState({ isLoading: false });
        return;
      }
      
      // Refresh word count after sending (sendMessage already handles this, but ensure we refresh)
      await fetchChat(chatId);
    } catch (error) {
      // Ensure loading is turned off on error
      useChatStore.setState({ isLoading: false });
      console.error('Error in handleSendMessage:', error);
      throw error;
    }
  };

  return (
    <AppLayout
      headerTitle={
        <div className="flex items-center gap-2">
          <span>Chats</span>
          {selectedPrompt && (
            <div className="flex items-center gap-1 px-2 py-1 bg-primary/10 text-primary rounded-lg text-sm">
              <FileText className="h-3 w-3" />
              <span>{selectedPrompt.name}</span>
            </div>
          )}
        </div>
      }
      headerActions={
        <div className="flex items-center gap-2">
          <QuickActionPills 
            onSelectionChange={handlePillSelectionChange}
            disabled={isLoading}
            resetTrigger={pillResetKey}
          />
          <Button 
            onClick={handleTextToSpeech} 
            variant="secondary"
            disabled={!currentChat || isGeneratingAudio}
            isLoading={isGeneratingAudio}
            className="h-8 px-3 text-xs"
          >
            <Volume2 className="h-3 w-3" />
            TTS
          </Button>
          <Button 
            onClick={handleSaveChat} 
            variant="secondary"
            disabled={!currentChat}
            className="h-8 px-3 text-xs"
          >
            <Save className="h-3 w-3" />
            Save Chat
          </Button>
          <Button 
            onClick={handleNewChat} 
            variant="primary"
            className="h-8 px-3 text-xs"
          >
            <Plus className="h-3 w-3" />
            New Chat
          </Button>
        </div>
      }
    >
      {error && (
        <div className="mb-4">
          <ErrorMessage message={error} />
          <button
            onClick={clearError}
            className="mt-2 text-sm text-primary hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      <div className="flex gap-3 h-[calc(100vh-7rem)]">
        {/* Chat History Sidebar */}
        <div className="w-48 flex-shrink-0 bg-bg-card rounded-lg border border-bg-muted overflow-hidden">
          <ChatHistory
            chats={chats}
            currentChatId={currentChat?.id}
            onSelectChat={handleSelectChat}
            onDeleteChat={handleDeleteChat}
            isLoading={isLoading && chats.length === 0}
          />
        </div>

        {/* Chat Window */}
        <div className="flex-1 bg-bg-card rounded-lg border border-bg-muted overflow-hidden">
          {currentChat ? (
            <ChatWindow
              messages={currentChat.messages}
              onSendMessage={handleSendMessage}
              isLoading={isLoading}
              wordCount={wordCount}
              chatId={currentChat.id}
              prependedText={selectedPillMessage}
            />
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-center p-6">
              <p className="text-text-secondary mb-4">Select a chat or create a new one to get started</p>
              <Button onClick={handleNewChat} variant="primary">
                <Plus className="h-4 w-4" />
                New Chat
              </Button>
            </div>
          )}
        </div>
      </div>

      {/* HTML Error Modal */}
      <HtmlErrorModal
        isOpen={!!htmlErrorContent}
        onClose={clearHtmlError}
        htmlContent={htmlErrorContent || ''}
        errorMessage={error || undefined}
      />
    </AppLayout>
  );
};

