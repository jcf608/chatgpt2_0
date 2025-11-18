import React from 'react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

interface AppLayoutProps {
  children: React.ReactNode;
  headerTitle?: string;
  headerActions?: React.ReactNode;
}

export const AppLayout: React.FC<AppLayoutProps> = ({
  children,
  headerTitle,
  headerActions,
}) => {
  return (
    <div className="flex h-screen bg-bg-main">
      <Sidebar />
      <div className="flex-1 flex flex-col ml-64">
        {(headerTitle || headerActions) && (
          <Header title={headerTitle}>{headerActions}</Header>
        )}
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </div>
  );
};

