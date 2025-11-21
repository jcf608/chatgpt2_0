import React, { useEffect, useRef } from 'react';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { LoadingSpinner } from '../common';
import type { Message } from '../../api/types';

interface ChatWindowProps {
  messages: Message[];
  onSendMessage: (content: string) => Promise<void>;
  isLoading?: boolean;
  wordCount?: number;
  chatId?: string | null;
  prependedText?: string;
}

export const ChatWindow: React.FC<ChatWindowProps> = ({
  messages,
  onSendMessage,
  isLoading = false,
  wordCount,
  chatId,
  prependedText = '',
}) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="flex flex-col h-full bg-bg-main">
      {/* Header with word count */}
      {wordCount !== undefined && (
        <div className="bg-bg-card border-b border-bg-muted px-3 py-1.5">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-text-primary">Chat</h2>
            <span className="text-[10px] text-text-secondary">
              {wordCount.toLocaleString()}w
            </span>
          </div>
        </div>
      )}

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto">
        {isLoading && messages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <div className="flex flex-col items-center gap-3">
              <LoadingSpinner size="lg" />
              <span className="text-text-secondary">AI is thinking...</span>
            </div>
          </div>
        ) : (
          <>
            <MessageList messages={messages} />
            <div ref={messagesEndRef} />
          </>
        )}
      </div>

      {/* Loading indicator when sending - always visible when loading and messages exist */}
      {isLoading && messages.length > 0 && (
        <div className="px-3 py-1.5 bg-bg-tertiary border-t border-bg-muted">
          <div className="flex items-center gap-1.5 text-text-secondary">
            <LoadingSpinner size="sm" />
            <span className="text-[10px] font-medium">AI is thinking...</span>
          </div>
        </div>
      )}

      {/* Message input */}
      <MessageInput 
        onSend={onSendMessage} 
        isLoading={isLoading}
        prependedText={prependedText}
        key={chatId || 'new-chat'}
      />
    </div>
  );
};

