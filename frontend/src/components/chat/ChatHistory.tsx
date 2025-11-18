import React from 'react';
import { MessageSquare, Trash2, Calendar, FileText } from 'lucide-react';
import { Button } from '../common';
import type { Chat } from '../../api/types';

interface ChatHistoryProps {
  chats: Chat[];
  currentChatId?: string;
  onSelectChat: (chat: Chat) => void;
  onDeleteChat: (chatId: string) => void;
  isLoading?: boolean;
}

export const ChatHistory: React.FC<ChatHistoryProps> = ({
  chats,
  currentChatId,
  onSelectChat,
  onDeleteChat,
  isLoading = false,
}) => {
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    return date.toLocaleDateString();
  };

  const getPreview = (chat: Chat) => {
    const userMessages = chat.messages.filter((m) => m.role === 'user');
    if (userMessages.length > 0) {
      return userMessages[0].content.substring(0, 100);
    }
    return 'No messages yet';
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-text-tertiary">Loading chats...</p>
      </div>
    );
  }

  if (chats.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center p-6">
        <MessageSquare className="h-12 w-12 text-text-tertiary mb-4" />
        <p className="text-text-secondary mb-2">No chats yet</p>
        <p className="text-sm text-text-tertiary">Start a new conversation to get started</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <div className="p-4 border-b border-bg-muted">
        <h2 className="text-lg font-semibold text-text-primary">Chat History</h2>
        <p className="text-sm text-text-tertiary mt-1">{chats.length} {chats.length === 1 ? 'chat' : 'chats'}</p>
      </div>
      <div className="flex-1 overflow-y-auto">
        <div className="divide-y divide-bg-muted">
          {chats.map((chat) => {
            const isActive = chat.id === currentChatId;
            const wordCount = chat.metadata?.word_count || 0;
            const messageCount = chat.messages.length;

            return (
              <div
                key={chat.id}
                className={`p-4 cursor-pointer transition-colors duration-default ease-in-out hover:bg-bg-tertiary ${
                  isActive ? 'bg-primary/10 border-l-4 border-primary' : ''
                }`}
                onClick={() => onSelectChat(chat)}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <MessageSquare className="h-4 w-4 text-primary flex-shrink-0" />
                      <h3 className="font-medium text-text-primary truncate">
                        {chat.title || 'Untitled Chat'}
                      </h3>
                    </div>
                    <p className="text-sm text-text-secondary line-clamp-2 mb-2">
                      {getPreview(chat)}
                    </p>
                    <div className="flex items-center gap-4 text-xs text-text-tertiary">
                      <div className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        {formatDate(chat.updated_at)}
                      </div>
                      <div className="flex items-center gap-1">
                        <FileText className="h-3 w-3" />
                        {messageCount} {messageCount === 1 ? 'message' : 'messages'}
                      </div>
                      {wordCount > 0 && (
                        <span>{wordCount.toLocaleString()} words</span>
                      )}
                    </div>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      if (confirm('Are you sure you want to delete this chat?')) {
                        onDeleteChat(chat.id);
                      }
                    }}
                    className="p-2 rounded-lg hover:bg-error/10 text-error transition-colors duration-default ease-in-out"
                    aria-label="Delete chat"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

