import React, { useState, useEffect } from 'react';
import { Sparkles, RefreshCw, FileText, Zap, MessageSquare, X } from 'lucide-react';

export interface QuickAction {
  id: string;
  label: string;
  message: string;
  icon?: React.ReactNode;
}

export const QUICK_ACTIONS: QuickAction[] = [
  {
    id: 'continue-all-parts',
    label: 'Continue (All Parts)',
    message: 'Continue the dialogue with you playing all parts. Maintain character consistency and keep the same engaging style with detailed descriptions.',
    icon: <MessageSquare className="h-3 w-3" />,
  },
  {
    id: 'no-repetition',
    label: 'No Repetition',
    message: 'Continue the conversation with fresh, varied phrasing. Avoid repetitious phrasing and overly long detailed passages. Keep it engaging and dynamic.',
    icon: <RefreshCw className="h-3 w-3" />,
  },
  {
    id: 'continue-natural',
    label: 'Continue Naturally',
    message: 'Continue the dialogue naturally from where we left off. Maintain character consistency and keep the same engaging style with detailed descriptions.',
    icon: <Sparkles className="h-3 w-3" />,
  },
  {
    id: 'detailed-immersive',
    label: 'Detailed & Immersive',
    message: 'Continue with more immersive dialogue that advances the relationship and story. Include sensory details and character reactions. Generate substantial content with rich descriptions.',
    icon: <FileText className="h-3 w-3" />,
  },
  {
    id: 'character-development',
    label: 'Character Development',
    message: 'Continue the conversation with detailed responses that deepen the connection between the characters. Focus on character development and emotional depth.',
    icon: <Zap className="h-3 w-3" />,
  },
  {
    id: 'extend-dialogue',
    label: 'Extend Dialogue',
    message: 'Continue the dialogue naturally, building on the previous exchange. Maintain character consistency and develop the scene further with rich detail.',
    icon: <MessageSquare className="h-3 w-3" />,
  },
];

interface QuickActionPillsProps {
  onSelectionChange: (selectedIds: string[], combinedMessage: string) => void;
  disabled?: boolean;
  resetTrigger?: string | number; // Trigger to reset selection
}

export const QuickActionPills: React.FC<QuickActionPillsProps> = ({
  onSelectionChange,
  disabled = false,
  resetTrigger,
}) => {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  // Reset selection when trigger changes
  useEffect(() => {
    if (resetTrigger !== undefined) {
      setSelectedIds(new Set());
      onSelectionChange([], '');
    }
  }, [resetTrigger, onSelectionChange]);

  const handleToggle = (actionId: string) => {
    if (disabled) return;

    const newSelected = new Set(selectedIds);
    if (newSelected.has(actionId)) {
      newSelected.delete(actionId);
    } else {
      newSelected.add(actionId);
    }
    setSelectedIds(newSelected);

    // Build combined message from selected actions
    const selectedActions = QUICK_ACTIONS.filter((action) => newSelected.has(action.id));
    const combinedMessage = selectedActions.map((action) => action.message).join(' ');

    // Notify parent of selection change
    onSelectionChange(Array.from(newSelected), combinedMessage);
  };

  return (
    <div className="flex flex-wrap gap-2 p-4 border-t border-bg-muted bg-bg-tertiary/30">
      {QUICK_ACTIONS.map((action) => {
        const isSelected = selectedIds.has(action.id);
        return (
          <button
            key={action.id}
            onClick={() => handleToggle(action.id)}
            disabled={disabled}
            className={`flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-full border transition-colors duration-default ease-in-out disabled:opacity-50 disabled:cursor-not-allowed ${
              isSelected
                ? 'bg-bg-muted border-bg-muted text-text-tertiary cursor-default'
                : 'border-bg-muted bg-bg-card text-text-secondary hover:bg-primary/10 hover:text-primary hover:border-primary/30'
            }`}
            title={action.message}
          >
            {action.icon}
            <span>{action.label}</span>
          </button>
        );
      })}
    </div>
  );
};

