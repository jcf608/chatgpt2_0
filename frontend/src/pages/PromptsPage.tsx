import React, { useEffect, useState } from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { PromptSelector } from '../components/prompts/PromptSelector';
import { PromptEditor } from '../components/prompts/PromptEditor';
import { SlideOut } from '../components/common';
import { Button, ErrorMessage } from '../components/common';
import { Plus, FileText } from 'lucide-react';
import { usePromptStore } from '../store/promptStore';
import type { Prompt } from '../api/types';

export const PromptsPage: React.FC = () => {
  const {
    prompts,
    selectedPrompt,
    isLoading,
    error,
    fetchPrompts,
    fetchPrompt,
    createPrompt,
    updatePrompt,
    deletePrompt,
    setSelectedPrompt,
    clearError,
  } = usePromptStore();

  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [editingPrompt, setEditingPrompt] = useState<Prompt | null>(null);

  useEffect(() => {
    fetchPrompts();
  }, [fetchPrompts]);

  const handleSelectPrompt = async (prompt: Prompt) => {
    await fetchPrompt(prompt.id);
    setEditingPrompt(prompt);
    setIsEditorOpen(true);
  };

  const handleNewPrompt = () => {
    setEditingPrompt(null);
    setIsEditorOpen(true);
  };

  const handleSavePrompt = async (data: { name: string; content: string }) => {
    try {
      if (editingPrompt) {
        await updatePrompt(editingPrompt.id, data);
      } else {
        await createPrompt(data);
      }
      await fetchPrompts();
      setIsEditorOpen(false);
      setEditingPrompt(null);
    } catch (err) {
      console.error('Failed to save prompt:', err);
    }
  };

  const handleDeletePrompt = async (id: string) => {
    try {
      await deletePrompt(id);
      setIsEditorOpen(false);
      setEditingPrompt(null);
      await fetchPrompts();
    } catch (err) {
      console.error('Failed to delete prompt:', err);
    }
  };

  return (
    <AppLayout
      headerTitle="Prompts"
      headerActions={
        <Button onClick={handleNewPrompt} variant="primary">
          <Plus className="h-4 w-4" />
          New Prompt
        </Button>
      }
    >
      {error && (
        <div className="mb-4">
          <ErrorMessage message={error} />
          <button
            onClick={clearError}
            className="mt-2 text-sm text-primary hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      <div className="flex gap-6 h-[calc(100vh-12rem)]">
        {/* Prompt Selector */}
        <div className="w-96 flex-shrink-0 bg-bg-card rounded-lg border border-bg-muted overflow-hidden">
          <PromptSelector
            prompts={prompts}
            selectedPromptId={selectedPrompt?.id}
            onSelectPrompt={handleSelectPrompt}
            isLoading={isLoading && prompts.length === 0}
          />
        </div>

        {/* Prompt Preview/Editor */}
        <div className="flex-1 bg-bg-card rounded-lg border border-bg-muted overflow-hidden">
          {selectedPrompt && !isEditorOpen ? (
            <div className="h-full flex flex-col">
              <div className="p-6 border-b border-bg-muted">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <FileText className="h-5 w-5 text-primary" />
                    <h2 className="text-xl font-semibold text-text-primary">{selectedPrompt.name}</h2>
                  </div>
                  <Button onClick={() => handleSelectPrompt(selectedPrompt)} variant="secondary">
                    Edit
                  </Button>
                </div>
              </div>
              <div className="flex-1 overflow-y-auto p-6">
                <pre className="whitespace-pre-wrap font-mono text-sm text-text-primary bg-bg-tertiary p-4 rounded-lg">
                  {selectedPrompt.content}
                </pre>
              </div>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-center p-6">
              <FileText className="h-12 w-12 text-text-tertiary mb-4" />
              <p className="text-text-secondary mb-2">Select a prompt to view or edit</p>
              <Button onClick={handleNewPrompt} variant="primary">
                <Plus className="h-4 w-4" />
                New Prompt
              </Button>
            </div>
          )}
        </div>
      </div>

      {/* Slide-out Editor */}
      <SlideOut
        isOpen={isEditorOpen}
        onClose={() => {
          setIsEditorOpen(false);
          setEditingPrompt(null);
        }}
        title={editingPrompt ? 'Edit Prompt' : 'New Prompt'}
        width="lg"
      >
        <PromptEditor
          prompt={editingPrompt}
          onSave={handleSavePrompt}
          onDelete={editingPrompt ? handleDeletePrompt : undefined}
          onCancel={() => {
            setIsEditorOpen(false);
            setEditingPrompt(null);
          }}
          isLoading={isLoading}
          error={error}
        />
      </SlideOut>
    </AppLayout>
  );
};

