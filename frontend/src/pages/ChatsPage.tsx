import React, { useEffect, useState } from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { ChatWindow } from '../components/chat/ChatWindow';
import { ChatHistory } from '../components/chat/ChatHistory';
import { Button, ErrorMessage } from '../components/common';
import { Plus, FileText } from 'lucide-react';
import { useChatStore } from '../store/chatStore';
import { useSettingsStore } from '../store/settingsStore';
import { usePromptStore } from '../store/promptStore';
import { apiClient } from '../api/client';
import type { Chat } from '../api/types';

export const ChatsPage: React.FC = () => {
  const {
    chats,
    currentChat,
    isLoading,
    error,
    fetchChats,
    fetchChat,
    createChat,
    deleteChat,
    sendMessage,
    setCurrentChat,
    clearError,
  } = useChatStore();

  const { apiProvider, selectedPromptId } = useSettingsStore();
  const { prompts, fetchPrompts } = usePromptStore();
  const [wordCount, setWordCount] = useState<number>(0);

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

  const handleNewChat = async () => {
    try {
      const chat = await createChat({
        title: 'New Chat',
        api_provider: apiProvider,
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
    
    if (!currentChat) {
      // Create a new chat if none exists
      chat = await createChat({
        title: content.substring(0, 50),
        api_provider: apiProvider,
      });
      chatId = chat.id;
    } else {
      chat = currentChat;
      chatId = currentChat.id;
    }

    // If this is the first message, add system prompts silently
    // System prompt (from system_prompt_id) must be FIRST, then selected prompt
    const isFirstMessage = !currentChat || currentChat.messages.length === 0;
    if (isFirstMessage) {
      // 1. FIRST: Add system prompt (from chat.system_prompt_id) if it exists
      if (chat.system_prompt_id) {
        try {
          const systemPrompt = await apiClient.getPrompt(chat.system_prompt_id);
          if (systemPrompt) {
            await apiClient.addMessage(chatId, {
              role: 'system',
              content: systemPrompt.content,
            });
          }
        } catch (error) {
          console.error('Failed to load system prompt:', error);
        }
      }

      // 2. SECOND: Add selected prompt (from settings) if it exists
      if (selectedPrompt) {
        await apiClient.addMessage(chatId, {
          role: 'system',
          content: selectedPrompt.content,
        });
      }
    }

    // Send the user's message
    await sendMessage(chatId, content);
    
    // Refresh word count after sending
    await fetchChat(chatId);
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
        <Button onClick={handleNewChat} variant="primary">
          <Plus className="h-4 w-4" />
          New Chat
        </Button>
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

      <div className="flex gap-6 h-[calc(100vh-12rem)]">
        {/* Chat History Sidebar */}
        <div className="w-80 flex-shrink-0 bg-bg-card rounded-lg border border-bg-muted overflow-hidden">
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
    </AppLayout>
  );
};

