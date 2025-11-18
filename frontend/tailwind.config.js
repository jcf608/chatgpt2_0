/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Backgrounds & Neutrals
        'bg-main': '#FAFAFA',
        'bg-card': '#FFFFFF',
        'bg-tertiary': '#F5F5F7',
        'bg-muted': '#E5E5E5',
        
        // Sidebar & Navigation
        'sidebar': '#2C2C2E',
        
        // Primary Colors (cool, muted)
        'primary': '#5E87B0',
        'primary-secondary': '#8BA3B8',
        'primary-accent': '#6B9AC4',
        
        // Text Colors (high contrast)
        'text-primary': '#1C1C1E',
        'text-secondary': '#3A3A3C',
        'text-tertiary': '#636366',
        'text-muted': '#8E8E93',
        
        // Semantic Colors
        'success': '#5A8F7B',
        'warning': '#D4A373',
        'error': '#B85C5C',
        'info': '#5E87B0',
      },
      transitionTimingFunction: {
        'ease-in-out': 'cubic-bezier(0.4, 0, 0.2, 1)',
      },
      transitionDuration: {
        'default': '300ms',
      },
    },
  },
  plugins: [],
}

