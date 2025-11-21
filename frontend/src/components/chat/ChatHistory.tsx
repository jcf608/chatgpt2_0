import React from 'react';
import { MessageSquare, Trash2, Calendar, FileText, Save, Copy } from 'lucide-react';
import { Button } from '../common';
import type { Chat } from '../../api/types';
import { useToastStore } from '../../store/toastStore';

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
  const toastStore = useToastStore();

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

  const formatChatForExport = (chat: Chat): string => {
    const lines: string[] = [];
    lines.push(chat.title || 'Untitled Chat');
    lines.push('='.repeat(50));
    lines.push(`Date: ${new Date(chat.created_at).toLocaleString()}`);
    lines.push(`Updated: ${new Date(chat.updated_at).toLocaleString()}`);
    if (chat.api_provider) {
      lines.push(`API Provider: ${chat.api_provider.toUpperCase()}`);
    }
    if (chat.voice) {
      lines.push(`Voice: ${chat.voice}`);
    }
    if (chat.metadata?.word_count) {
      lines.push(`Word Count: ${chat.metadata.word_count.toLocaleString()}`);
    }
    lines.push('='.repeat(50));
    lines.push('');

    chat.messages.forEach((message) => {
      switch (message.role) {
        case 'system':
          lines.push('SYSTEM:');
          break;
        case 'user':
          lines.push('USER:');
          break;
        case 'assistant':
          lines.push('ASSISTANT:');
          break;
      }
      lines.push(message.content);
      lines.push('');
    });

    return lines.join('\n');
  };

  const handleSaveChat = (e: React.MouseEvent, chat: Chat) => {
    e.stopPropagation();
    try {
      const content = formatChatForExport(chat);
      const blob = new Blob([content], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      
      // Generate filename with timestamp
      const timestamp = new Date(chat.updated_at).toISOString().replace(/[:.]/g, '-').slice(0, -5);
      const title = (chat.title || 'Untitled Chat').replace(/[^\w\s-]/g, '').replace(/\s+/g, '_').substring(0, 30);
      a.download = `${timestamp}_${title}.txt`;
      
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      toastStore.addToast('Chat saved successfully', 'success');
    } catch (error) {
      toastStore.addToast('Failed to save chat', 'error');
    }
  };

  const handleCopyChat = async (e: React.MouseEvent, chat: Chat) => {
    e.stopPropagation();
    try {
      const content = formatChatForExport(chat);
      await navigator.clipboard.writeText(content);
      toastStore.addToast('Chat copied to clipboard', 'success');
    } catch (error) {
      toastStore.addToast('Failed to copy chat', 'error');
    }
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
      <div className="p-3 border-b border-bg-muted">
        <h2 className="text-base font-semibold text-text-primary">Chat History</h2>
        <p className="text-xs text-text-tertiary mt-1">{chats.length} {chats.length === 1 ? 'chat' : 'chats'}</p>
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
                className={`p-3 cursor-pointer transition-colors duration-default ease-in-out hover:bg-bg-tertiary ${
                  isActive ? 'bg-primary/10 border-l-4 border-primary' : ''
                }`}
                onClick={() => onSelectChat(chat)}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5 mb-1">
                      <MessageSquare className="h-3.5 w-3.5 text-primary flex-shrink-0" />
                      <h3 className="text-sm font-medium text-text-primary truncate">
                        {chat.title || 'Untitled Chat'}
                      </h3>
                    </div>
                    <p className="text-xs text-text-secondary line-clamp-2 mb-1.5">
                      {getPreview(chat)}
                    </p>
                    <div className="flex items-center gap-3 text-[10px] text-text-tertiary">
                      <div className="flex items-center gap-0.5">
                        <Calendar className="h-2.5 w-2.5" />
                        {formatDate(chat.updated_at)}
                      </div>
                      <div className="flex items-center gap-0.5">
                        <FileText className="h-2.5 w-2.5" />
                        {messageCount}
                      </div>
                      {wordCount > 0 && (
                        <span>{wordCount.toLocaleString()}w</span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-0.5">
                    <button
                      onClick={(e) => handleSaveChat(e, chat)}
                      className="p-1.5 rounded-lg hover:bg-primary/10 text-primary transition-colors duration-default ease-in-out"
                      aria-label="Save chat"
                      title="Save chat to file"
                    >
                      <Save className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={(e) => handleCopyChat(e, chat)}
                      className="p-1.5 rounded-lg hover:bg-primary/10 text-primary transition-colors duration-default ease-in-out"
                      aria-label="Copy chat"
                      title="Copy chat to clipboard"
                    >
                      <Copy className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (confirm('Are you sure you want to delete this chat?')) {
                          onDeleteChat(chat.id);
                        }
                      }}
                      className="p-1.5 rounded-lg hover:bg-error/10 text-error transition-colors duration-default ease-in-out"
                      aria-label="Delete chat"
                      title="Delete chat"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

