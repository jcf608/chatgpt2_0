import React from 'react';
import { MessageSquare, FileText, Settings, Home, Volume2 } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';

export const Sidebar: React.FC = () => {
  const location = useLocation();

  const navItems = [
    { path: '/', icon: Home, label: 'Home' },
    { path: '/chats', icon: MessageSquare, label: 'Chats' },
    { path: '/prompts', icon: FileText, label: 'Prompts' },
    { path: '/audio', icon: Volume2, label: 'Audio' },
    { path: '/settings', icon: Settings, label: 'Settings' },
  ];

  return (
    <aside className="w-16 bg-sidebar text-white h-screen fixed left-0 top-0 flex flex-col">
      <div className="p-3 border-b border-sidebar/50 flex items-center justify-center">
        <h1 className="text-lg font-bold">C</h1>
      </div>
      <nav className="flex-1 p-2">
        <ul className="space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <li key={item.path}>
                <Link
                  to={item.path}
                  className={`flex items-center justify-center p-3 rounded-lg transition-all duration-default ease-in-out ${
                    isActive
                      ? 'bg-primary text-white'
                      : 'text-white/70 hover:bg-white/10 hover:text-white'
                  }`}
                  title={item.label}
                >
                  <Icon className="h-5 w-5" />
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
};

