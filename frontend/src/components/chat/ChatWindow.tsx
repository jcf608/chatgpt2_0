import React, { useEffect, useRef, useState } from 'react';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { QuickActionPills } from './QuickActionPills';
import { LoadingSpinner } from '../common';
import type { Message } from '../../api/types';

interface ChatWindowProps {
  messages: Message[];
  onSendMessage: (content: string) => Promise<void>;
  isLoading?: boolean;
  wordCount?: number;
  chatId?: string | null;
}

export const ChatWindow: React.FC<ChatWindowProps> = ({
  messages,
  onSendMessage,
  isLoading = false,
  wordCount,
  chatId,
}) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [selectedPillMessage, setSelectedPillMessage] = useState<string>('');
  const [pillResetKey, setPillResetKey] = useState<number>(0);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Reset selected pills when chat changes
  useEffect(() => {
    setSelectedPillMessage('');
    setPillResetKey((prev) => prev + 1);
  }, [chatId]);

  const handlePillSelectionChange = (selectedIds: string[], combinedMessage: string) => {
    setSelectedPillMessage(combinedMessage);
  };

  const handleSendWithPills = async (userContent: string) => {
    // Content already includes pill text from the input field
    if (userContent.trim()) {
      // Clear selected pills after sending
      setSelectedPillMessage('');
      setPillResetKey((prev) => prev + 1);
      await onSendMessage(userContent.trim());
    }
  };

  return (
    <div className="flex flex-col h-full bg-bg-main">
      {/* Header with word count */}
      {wordCount !== undefined && (
        <div className="bg-bg-card border-b border-bg-muted px-6 py-3">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-text-primary">Chat</h2>
            <span className="text-sm text-text-secondary">
              {wordCount.toLocaleString()} {wordCount === 1 ? 'word' : 'words'}
            </span>
          </div>
        </div>
      )}

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto">
        {isLoading && messages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <LoadingSpinner size="lg" />
          </div>
        ) : (
          <>
            <MessageList messages={messages} />
            <div ref={messagesEndRef} />
          </>
        )}
      </div>

      {/* Loading indicator when sending */}
      {isLoading && messages.length > 0 && (
        <div className="px-4 py-2 bg-bg-tertiary border-t border-bg-muted">
          <div className="flex items-center gap-2 text-text-secondary">
            <LoadingSpinner size="sm" />
            <span className="text-sm">AI is thinking...</span>
          </div>
        </div>
      )}

      {/* Message input */}
      <MessageInput 
        onSend={handleSendWithPills} 
        isLoading={isLoading}
        prependedText={selectedPillMessage}
        key={chatId || 'new-chat'}
      />

      {/* Quick Action Pills - positioned below input */}
      <QuickActionPills 
        onSelectionChange={handlePillSelectionChange}
        disabled={isLoading}
        resetTrigger={pillResetKey}
      />
    </div>
  );
};

