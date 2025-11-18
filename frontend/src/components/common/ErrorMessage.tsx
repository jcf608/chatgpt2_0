import React, { useState } from 'react';
import { AlertCircle, Copy, Check } from 'lucide-react';

interface ErrorMessageProps {
  message: string;
  details?: string;
  className?: string;
}

export const ErrorMessage: React.FC<ErrorMessageProps> = ({
  message,
  details,
  className = '',
}) => {
  const [copied, setCopied] = useState(false);

  const copyToClipboard = () => {
    const text = details ? `${message}\n\n${details}` : message;
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className={`bg-error/10 border-l-4 border-error p-4 rounded-lg ${className}`}>
      <div className="flex items-start gap-3">
        <AlertCircle className="h-5 w-5 text-error flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <p className="text-sm font-medium text-error mb-1">{message}</p>
          {details && (
            <div className="mt-2">
              <details className="text-sm text-text-secondary">
                <summary className="cursor-pointer hover:text-text-primary transition-colors">
                  Technical Details
                </summary>
                <pre className="mt-2 p-2 bg-bg-tertiary rounded text-xs overflow-x-auto">
                  {details}
                </pre>
              </details>
            </div>
          )}
        </div>
        {(message || details) && (
          <button
            onClick={copyToClipboard}
            className="p-1 rounded hover:bg-error/20 transition-colors"
            aria-label="Copy to clipboard"
          >
            {copied ? (
              <Check className="h-4 w-4 text-success" />
            ) : (
              <Copy className="h-4 w-4 text-error" />
            )}
          </button>
        )}
      </div>
    </div>
  );
};

