import React, { useEffect } from 'react';
import { X } from 'lucide-react';

interface SlideOutProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  side?: 'left' | 'right';
  width?: 'sm' | 'md' | 'lg' | 'xl';
}

export const SlideOut: React.FC<SlideOutProps> = ({
  isOpen,
  onClose,
  title,
  children,
  side = 'right',
  width = 'md',
}) => {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  const widthClasses = {
    sm: 'w-80',
    md: 'w-96',
    lg: 'w-[32rem]',
    xl: 'w-[40rem]',
  };

  const transformClass = side === 'right' 
    ? isOpen ? 'translate-x-0' : 'translate-x-full'
    : isOpen ? 'translate-x-0' : '-translate-x-full';

  return (
    <>
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 transition-opacity duration-default ease-in-out"
          onClick={onClose}
        />
      )}
      <div
        className={`fixed top-0 ${side === 'right' ? 'right-0' : 'left-0'} h-full ${widthClasses[width]} bg-bg-card shadow-xl z-50 transform transition-transform duration-default ease-in-out ${transformClass} flex flex-col`}
      >
        {title && (
          <div className="flex items-center justify-between p-6 border-b border-bg-muted">
            <h2 className="text-xl font-semibold text-text-primary">{title}</h2>
            <button
              onClick={onClose}
              className="p-1 rounded-lg hover:bg-bg-tertiary transition-colors duration-default ease-in-out"
              aria-label="Close"
            >
              <X className="h-5 w-5 text-text-secondary" />
            </button>
          </div>
        )}
        <div className="flex-1 overflow-y-auto p-6">{children}</div>
      </div>
    </>
  );
};

