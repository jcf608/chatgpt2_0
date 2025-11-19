import React from 'react';
import { Modal } from './Modal';
import { AlertCircle } from 'lucide-react';

interface HtmlErrorModalProps {
  isOpen: boolean;
  onClose: () => void;
  htmlContent: string;
  errorMessage?: string;
}

export const HtmlErrorModal: React.FC<HtmlErrorModalProps> = ({
  isOpen,
  onClose,
  htmlContent,
  errorMessage,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={
        <div className="flex items-center gap-2">
          <AlertCircle className="h-5 w-5 text-error" />
          <span>Venice.ai Error Response</span>
        </div>
      }
      size="xl"
    >
      <div className="space-y-4">
        {errorMessage && (
          <div className="bg-error/10 border-l-4 border-error p-4 rounded-lg">
            <p className="text-sm font-medium text-error">{errorMessage}</p>
          </div>
        )}
        <div className="border border-bg-muted rounded-lg overflow-hidden">
          <div className="bg-bg-tertiary px-4 py-2 border-b border-bg-muted">
            <p className="text-xs font-medium text-text-secondary">HTML Response from Venice.ai</p>
          </div>
          <div className="p-4 bg-bg-main max-h-[60vh] overflow-auto">
            <iframe
              srcDoc={htmlContent}
              className="w-full h-full min-h-[400px] border-0"
              title="Venice.ai Error Response"
              sandbox="allow-same-origin allow-scripts"
            />
          </div>
        </div>
        <div className="flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors duration-default ease-in-out"
          >
            Close
          </button>
        </div>
      </div>
    </Modal>
  );
};

