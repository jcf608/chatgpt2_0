import React from 'react';
import { User, Bot, Copy, Check } from 'lucide-react';
import type { Message } from '../../api/types';

interface MessageListProps {
  messages: Message[];
}

export const MessageList: React.FC<MessageListProps> = ({ messages }) => {
  const [copiedId, setCopiedId] = React.useState<string | null>(null);

  const copyToClipboard = (content: string, messageId: string) => {
    navigator.clipboard.writeText(content).then(() => {
      setCopiedId(messageId);
      setTimeout(() => setCopiedId(null), 2000);
    });
  };

  const formatContent = (content: string) => {
    // Handle roleplay formatting (DADDY:, BARRY:, SAMMY:, etc.)
    const roleplayPattern = /^([A-Z_]+):\s*(.+)$/m;
    const match = content.match(roleplayPattern);
    
    if (match) {
      const [, character, text] = match;
      return (
        <div>
          <span className="font-semibold text-primary-accent">{character}:</span>
          <span className="ml-2">{text}</span>
        </div>
      );
    }
    
    // Simple line breaks for regular messages
    return content.split('\n').map((line, i) => (
      <React.Fragment key={i}>
        {line}
        {i < content.split('\n').length - 1 && <br />}
      </React.Fragment>
    ));
  };

  if (messages.length === 0) {
    return (
      <div className="flex items-center justify-center h-full text-text-tertiary">
        <p>No messages yet. Start a conversation!</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-2 p-2">
      {messages.map((message) => {
        const isUser = message.role === 'user';
        const isSystem = message.role === 'system';
        
        if (isSystem) return null; // Skip system messages in display

        return (
          <div
            key={message.id}
            className={`flex gap-2 ${isUser ? 'justify-end' : 'justify-start'}`}
          >
            {!isUser && (
              <div className="flex-shrink-0 w-6 h-6 rounded-full bg-primary flex items-center justify-center">
                <Bot className="h-3.5 w-3.5 text-white" />
              </div>
            )}
            <div
              className={`max-w-[90%] rounded-lg p-2 text-sm leading-relaxed ${
                isUser
                  ? 'bg-primary text-white'
                  : 'bg-bg-card border border-bg-muted text-text-primary'
              }`}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1">{formatContent(message.content)}</div>
                <button
                  onClick={() => copyToClipboard(message.content, message.id)}
                  className={`flex-shrink-0 p-0.5 rounded hover:bg-black/10 transition-colors ${
                    isUser ? 'text-white/80' : 'text-text-tertiary'
                  }`}
                  aria-label="Copy message"
                >
                  {copiedId === message.id ? (
                    <Check className="h-3 w-3 text-success" />
                  ) : (
                    <Copy className="h-3 w-3" />
                  )}
                </button>
              </div>
              <div
                className={`text-[9px] mt-1 ${
                  isUser ? 'text-white/70' : 'text-text-tertiary'
                }`}
              >
                {new Date(message.created_at).toLocaleTimeString()}
              </div>
            </div>
            {isUser && (
              <div className="flex-shrink-0 w-6 h-6 rounded-full bg-primary-secondary flex items-center justify-center">
                <User className="h-3.5 w-3.5 text-white" />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

