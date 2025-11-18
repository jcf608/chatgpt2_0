import React, { useState, useRef, useEffect } from 'react';
import { Send, Loader2 } from 'lucide-react';
import { Button } from '../common';

interface MessageInputProps {
  onSend: (content: string) => Promise<void>;
  isLoading?: boolean;
  placeholder?: string;
  prependedText?: string; // Text to prepend to the input (from pills)
}

export const MessageInput: React.FC<MessageInputProps> = ({
  onSend,
  isLoading = false,
  placeholder = 'Type your message...',
  prependedText = '',
}) => {
  const [content, setContent] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const isUserEditingRef = useRef<boolean>(false);

  // Update content when prependedText changes (from pills)
  useEffect(() => {
    // Only auto-update if user hasn't manually edited
    if (!isUserEditingRef.current) {
      if (prependedText) {
        setContent(prependedText);
      } else {
        // When pills are deselected, keep user content if it exists
        // Only clear if content was empty
        if (!content.trim()) {
          setContent('');
        }
      }
    } else if (prependedText) {
      // If user is editing and pills are selected, prepend the new pill text
      // But only if current content doesn't already start with it
      if (!content.startsWith(prependedText)) {
        setContent(`${prependedText} ${content}`.trim());
      }
    } else {
      // If pills are deselected but user was editing, keep their content
      // (content already has user's text, so no change needed)
    }
    isUserEditingRef.current = false;
  }, [prependedText]);

  // Track when user manually edits
  const handleContentChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    isUserEditingRef.current = true;
    setContent(e.target.value);
  };

  // Auto-focus textarea on mount
  useEffect(() => {
    if (textareaRef.current && !isLoading) {
      textareaRef.current.focus();
    }
  }, [isLoading]);

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${textareaRef.current.scrollHeight}px`;
    }
  }, [content]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // Allow sending even if content is empty (pills might be selected)
    if (isLoading) return;

    const messageContent = content.trim();
    setContent('');
    isUserEditingRef.current = false; // Reset editing flag after sending
    
    // Reset textarea height
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }

    await onSend(messageContent);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;

  return (
    <form onSubmit={handleSubmit} className="border-t border-bg-muted p-4 bg-bg-card">
      <div className="flex gap-2 items-end">
        <div className="flex-1">
          <textarea
            ref={textareaRef}
            value={content}
            onChange={handleContentChange}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            disabled={isLoading}
            rows={1}
            className="w-full px-4 py-3 border border-bg-muted rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent resize-none transition-all duration-default ease-in-out disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ minHeight: '48px', maxHeight: '200px' }}
          />
          <div className="flex items-center justify-between mt-1">
            <span className="text-xs text-text-tertiary">
              {wordCount} {wordCount === 1 ? 'word' : 'words'}
            </span>
            <span className="text-xs text-text-tertiary">
              Press Enter to send, Shift+Enter for new line
            </span>
          </div>
        </div>
        <Button
          type="submit"
          variant="primary"
          isLoading={isLoading}
          disabled={isLoading}
          className="h-12 px-6"
        >
          {!isLoading && <Send className="h-4 w-4" />}
          Send
        </Button>
      </div>
    </form>
  );
};

