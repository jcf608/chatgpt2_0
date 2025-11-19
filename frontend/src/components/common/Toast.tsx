import React from 'react';
import { X, CheckCircle, AlertCircle, Info, AlertTriangle } from 'lucide-react';
import { useToastStore, type Toast } from '../../store/toastStore';

const ToastIcon: React.FC<{ type: Toast['type'] }> = ({ type }) => {
  const className = 'h-5 w-5 flex-shrink-0';
  switch (type) {
    case 'success':
      return <CheckCircle className={`${className} text-success`} />;
    case 'error':
      return <AlertCircle className={`${className} text-error`} />;
    case 'warning':
      return <AlertTriangle className={`${className} text-warning`} />;
    default:
      return <Info className={`${className} text-primary`} />;
  }
};

const ToastItem: React.FC<{ toast: Toast }> = ({ toast }) => {
  const { removeToast } = useToastStore();

  const bgColor = {
    success: 'bg-success/10 border-success',
    error: 'bg-error/10 border-error',
    warning: 'bg-warning/10 border-warning',
    info: 'bg-primary/10 border-primary',
  }[toast.type];

  const textColor = {
    success: 'text-success',
    error: 'text-error',
    warning: 'text-warning',
    info: 'text-primary',
  }[toast.type];

  return (
    <div
      className={`flex items-start gap-3 p-4 rounded-lg border-l-4 ${bgColor} shadow-lg min-w-[300px] max-w-[500px] transition-all duration-default ease-in-out`}
    >
      <ToastIcon type={toast.type} />
      <div className="flex-1 min-w-0">
        <p className={`text-sm font-medium ${textColor} break-words`}>{toast.message}</p>
      </div>
      <button
        onClick={() => removeToast(toast.id)}
        className={`p-1 rounded hover:bg-black/10 transition-colors ${textColor}`}
        aria-label="Dismiss"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};

export const ToastContainer: React.FC = () => {
  const { toasts } = useToastStore();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none">
      {toasts.map((toast) => (
        <div key={toast.id} className="pointer-events-auto">
          <ToastItem toast={toast} />
        </div>
      ))}
    </div>
  );
};

