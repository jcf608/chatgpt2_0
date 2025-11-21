import React from 'react';

interface HeaderProps {
  title?: string;
  children?: React.ReactNode;
}

export const Header: React.FC<HeaderProps> = ({ title, children }) => {
  return (
    <header className="bg-bg-card border-b border-bg-muted px-3 py-2">
      <div className="flex items-center justify-between">
        {title && <h1 className="text-base font-semibold text-text-primary">{title}</h1>}
        {children && <div className="flex items-center gap-2">{children}</div>}
      </div>
    </header>
  );
};

