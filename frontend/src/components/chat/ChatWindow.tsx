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
}

export const ChatWindow: React.FC<ChatWindowProps> = ({
  messages,
  onSendMessage,
  isLoading = false,
  wordCount,
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
      <MessageInput onSend={onSendMessage} isLoading={isLoading} />
    </div>
  );
};

