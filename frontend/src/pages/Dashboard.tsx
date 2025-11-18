import React from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { MessageSquare, FileText, Settings } from 'lucide-react';

export const Dashboard: React.FC = () => {
  return (
    <AppLayout headerTitle="Dashboard">
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="card">
            <div className="flex items-center gap-4">
              <div className="bg-primary p-3 rounded-lg">
                <MessageSquare className="h-6 w-6 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Chats</h3>
                <p className="text-text-secondary">Manage your conversations</p>
              </div>
            </div>
          </div>
          <div className="card">
            <div className="flex items-center gap-4">
              <div className="bg-primary-secondary p-3 rounded-lg">
                <FileText className="h-6 w-6 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Prompts</h3>
                <p className="text-text-secondary">System prompts library</p>
              </div>
            </div>
          </div>
          <div className="card">
            <div className="flex items-center gap-4">
              <div className="bg-primary-accent p-3 rounded-lg">
                <Settings className="h-6 w-6 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Settings</h3>
                <p className="text-text-secondary">Configure your preferences</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
};

