import React, { useState, useEffect } from 'react';
import { Save, Trash2, X } from 'lucide-react';
import { Button, Input, ErrorMessage } from '../common';
import type { Prompt } from '../../api/types';

interface PromptEditorProps {
  prompt?: Prompt | null;
  onSave: (data: { name: string; content: string }) => Promise<void>;
  onDelete?: (id: string) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  error?: string | null;
}

export const PromptEditor: React.FC<PromptEditorProps> = ({
  prompt,
  onSave,
  onDelete,
  onCancel,
  isLoading = false,
  error,
}) => {
  const [name, setName] = useState('');
  const [content, setContent] = useState('');

  useEffect(() => {
    if (prompt) {
      setName(prompt.name);
      setContent(prompt.content);
    } else {
      setName('');
      setContent('');
    }
  }, [prompt]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !content.trim()) return;
    await onSave({ name: name.trim(), content: content.trim() });
  };

  const handleDelete = async () => {
    if (!prompt || !onDelete) return;
    if (confirm('Are you sure you want to delete this prompt?')) {
      await onDelete(prompt.id);
    }
  };

  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
  const charCount = content.length;

  return (
    <div className="flex flex-col h-full">
      <div className="p-6 border-b border-bg-muted">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-text-primary">
            {prompt ? 'Edit Prompt' : 'New Prompt'}
          </h2>
          <button
            onClick={onCancel}
            className="p-2 rounded-lg hover:bg-bg-tertiary transition-colors"
            aria-label="Close"
          >
            <X className="h-5 w-5 text-text-secondary" />
          </button>
        </div>
        {error && (
          <div className="mb-4">
            <ErrorMessage message={error} />
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="flex-1 flex flex-col overflow-hidden">
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          <Input
            label="Prompt Name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter prompt name..."
            required
            disabled={isLoading}
          />

          <div>
            <label className="block text-sm font-medium text-text-secondary mb-1">
              Prompt Content
            </label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Enter prompt content..."
              required
              disabled={isLoading}
              rows={15}
              className="w-full px-4 py-3 border border-bg-muted rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent resize-none transition-all duration-default ease-in-out disabled:opacity-50 disabled:cursor-not-allowed font-mono text-sm"
            />
            <div className="flex items-center justify-between mt-1">
              <span className="text-xs text-text-tertiary">
                {wordCount} {wordCount === 1 ? 'word' : 'words'} • {charCount.toLocaleString()} characters
              </span>
            </div>
          </div>
        </div>

        <div className="p-6 border-t border-bg-muted flex items-center justify-between gap-4">
          <div>
            {prompt && onDelete && (
              <Button
                type="button"
                variant="danger"
                onClick={handleDelete}
                disabled={isLoading}
              >
                <Trash2 className="h-4 w-4" />
                Delete
              </Button>
            )}
          </div>
          <div className="flex gap-2">
            <Button type="button" variant="outline" onClick={onCancel} disabled={isLoading}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={isLoading} disabled={!name.trim() || !content.trim()}>
              <Save className="h-4 w-4" />
              Save
            </Button>
          </div>
        </div>
      </form>
    </div>
  );
};

