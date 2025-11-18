import React, { useState, useEffect, useRef } from 'react';
import { FileText, Search, Check, Copy } from 'lucide-react';
import { Input } from '../common';
import type { Prompt } from '../../api/types';

interface PromptSelectorProps {
  prompts: Prompt[];
  selectedPromptId?: string;
  activePromptId?: string | null; // The prompt selected for use in chats
  onSelectPrompt: (prompt: Prompt) => void;
  onSelectActivePrompt?: (promptId: string | null) => void;
  isLoading?: boolean;
}

export const PromptSelector: React.FC<PromptSelectorProps> = ({
  prompts,
  selectedPromptId,
  activePromptId,
  onSelectPrompt,
  onSelectActivePrompt,
  isLoading = false,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const selectedPromptRef = useRef<HTMLDivElement>(null);
  const listContainerRef = useRef<HTMLDivElement>(null);

  // Sort prompts: selected first, then alphabetically
  const sortedPrompts = [...prompts].sort((a, b) => {
    if (selectedPromptId) {
      if (a.id === selectedPromptId) return -1;
      if (b.id === selectedPromptId) return 1;
    }
    return a.name.localeCompare(b.name);
  });

  const filteredPrompts = sortedPrompts.filter((prompt) =>
    prompt.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    prompt.content.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Scroll selected prompt into view when it changes
  useEffect(() => {
    if (selectedPromptId && selectedPromptRef.current && listContainerRef.current) {
      // Small delay to ensure DOM is updated
      setTimeout(() => {
        selectedPromptRef.current?.scrollIntoView({
          behavior: 'smooth',
          block: 'start',
          inline: 'nearest'
        });
      }, 100);
    }
  }, [selectedPromptId]);

  const getPreview = (content: string, maxLength: number = 150) => {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  };

  const copyToClipboard = (content: string, promptId: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent triggering the select action
    navigator.clipboard.writeText(content).then(() => {
      setCopiedId(promptId);
      setTimeout(() => setCopiedId(null), 2000);
    });
  };

  const handleRadioClick = (promptId: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent triggering the select action
    if (onSelectActivePrompt) {
      // Toggle: if already active, deselect it
      onSelectActivePrompt(activePromptId === promptId ? null : promptId);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-text-tertiary">Loading prompts...</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <div className="p-4 border-b border-bg-muted">
        <h2 className="text-lg font-semibold text-text-primary mb-3">Select Prompt</h2>
        <Input
          type="text"
          placeholder="Search prompts..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full"
        />
      </div>
      <div className="flex-1 overflow-y-auto" ref={listContainerRef}>
        {filteredPrompts.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center p-6">
            <FileText className="h-12 w-12 text-text-tertiary mb-4" />
            <p className="text-text-secondary">
              {searchQuery ? 'No prompts match your search' : 'No prompts available'}
            </p>
          </div>
        ) : (
          <div className="divide-y divide-bg-muted">
            {filteredPrompts.map((prompt) => {
              const isSelected = prompt.id === selectedPromptId;
              return (
                <div
                  key={prompt.id}
                  ref={isSelected ? selectedPromptRef : null}
                  className={`p-4 cursor-pointer transition-colors duration-default ease-in-out hover:bg-bg-tertiary ${
                    isSelected ? 'bg-primary/10 border-l-4 border-primary' : ''
                  }`}
                  onClick={() => onSelectPrompt(prompt)}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        {onSelectActivePrompt && (
                          <button
                            onClick={(e) => handleRadioClick(prompt.id, e)}
                            className="p-1 rounded-full hover:bg-primary/10 transition-colors duration-default ease-in-out flex-shrink-0"
                            aria-label={activePromptId === prompt.id ? 'Deselect prompt' : 'Select prompt for chat'}
                            title={activePromptId === prompt.id ? 'Active prompt (click to deselect)' : 'Select for chat'}
                          >
                            <div className={`h-4 w-4 rounded-full border-2 transition-colors duration-default ease-in-out ${
                              activePromptId === prompt.id
                                ? 'bg-primary border-primary'
                                : 'border-text-tertiary hover:border-primary'
                            }`}>
                              {activePromptId === prompt.id && (
                                <div className="h-full w-full rounded-full bg-primary" />
                              )}
                            </div>
                          </button>
                        )}
                        <FileText className="h-4 w-4 text-primary flex-shrink-0" />
                        <h3 className="font-medium text-text-primary">{prompt.name}</h3>
                        {isSelected && (
                          <Check className="h-4 w-4 text-success flex-shrink-0" />
                        )}
                      </div>
                      <p className="text-sm text-text-secondary line-clamp-3">
                        {getPreview(prompt.content)}
                      </p>
                    </div>
                    <button
                      onClick={(e) => copyToClipboard(prompt.content, prompt.id, e)}
                      className="p-2 rounded-lg hover:bg-primary/10 text-text-tertiary hover:text-primary transition-colors duration-default ease-in-out flex-shrink-0"
                      aria-label="Copy prompt content"
                      title="Copy to clipboard"
                    >
                      {copiedId === prompt.id ? (
                        <Check className="h-4 w-4 text-success" />
                      ) : (
                        <Copy className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

