import React, { useState } from 'react';
import { FileText, Search, Check } from 'lucide-react';
import { Input } from '../common';
import type { Prompt } from '../../api/types';

interface PromptSelectorProps {
  prompts: Prompt[];
  selectedPromptId?: string;
  onSelectPrompt: (prompt: Prompt) => void;
  isLoading?: boolean;
}

export const PromptSelector: React.FC<PromptSelectorProps> = ({
  prompts,
  selectedPromptId,
  onSelectPrompt,
  isLoading = false,
}) => {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredPrompts = prompts.filter((prompt) =>
    prompt.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    prompt.content.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getPreview = (content: string, maxLength: number = 150) => {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
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
      <div className="flex-1 overflow-y-auto">
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
                  className={`p-4 cursor-pointer transition-colors duration-default ease-in-out hover:bg-bg-tertiary ${
                    isSelected ? 'bg-primary/10 border-l-4 border-primary' : ''
                  }`}
                  onClick={() => onSelectPrompt(prompt)}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
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

