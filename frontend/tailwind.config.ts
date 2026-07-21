import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        cyber: { black: '#0a0a0f', darker: '#0d0d1a', dark: '#12122a', mid: '#1a1a3e', light: '#2a2a5e', card: '#141428', border: '#2a2a5e' },
        neon: { cyan: '#00f0ff', blue: '#4d7cff', purple: '#8b5cf6', pink: '#ff2d7b', green: '#00ff87', amber: '#ffb800', red: '#ff3355', teal: '#00d4aa' },
      },
      fontFamily: { mono: ['JetBrains Mono', 'Fira Code', 'monospace'], sans: ['Inter', 'system-ui', 'sans-serif'] },
      boxShadow: {
        'neon-cyan': '0 0 10px rgba(0,240,255,0.3), 0 0 20px rgba(0,240,255,0.1)',
        'neon-purple': '0 0 10px rgba(139,92,246,0.3), 0 0 20px rgba(139,92,246,0.1)',
        'neon-pink': '0 0 10px rgba(255,45,123,0.3), 0 0 20px rgba(255,45,123,0.1)',
        'neon-green': '0 0 10px rgba(0,255,135,0.3), 0 0 20px rgba(0,255,135,0.1)',
        'neon-amber': '0 0 10px rgba(255,184,0,0.3), 0 0 20px rgba(255,184,0,0.1)',
        'neon-red': '0 0 10px rgba(255,51,85,0.3), 0 0 20px rgba(255,51,85,0.1)',
      },
      animation: {
        'pulse-neon': 'pulseNeon 2s ease-in-out infinite',
        'slide-up': 'slideUp 0.3s ease-out',
        'fade-in': 'fadeIn 0.2s ease-out',
      },
      keyframes: {
        pulseNeon: { '0%,100%': { opacity: '1' }, '50%': { opacity: '0.85' } },
        slideUp: { '0%': { opacity: '0', transform: 'translateY(12px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
      },
    },
  },
  plugins: [],
};
export default config;
