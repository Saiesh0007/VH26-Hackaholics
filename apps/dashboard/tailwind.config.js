/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "#fcfcfc",
        surface: "#ffffff",
        surfaceHover: "#f8fafc",
        border: "#e5e7eb",
        primary: "#ea580c", // Orange accent
        secondary: "#eab308", // Yellow accent
        success: "#22c55e",
        warning: "#f59e0b",
        danger: "#ef4444",
        
        // Priority Tiers adjusted for light theme visibility
        critical: "#dc2626", // Red-600
        high: "#ea580c", // Orange-600
        normal: "#2563eb", // Blue-600
        low: "#475569" // Slate-600
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        display: ['Outfit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'fade-in': 'fadeIn 0.5s ease-out forwards',
        'slide-up': 'slideUp 0.5s ease-out forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        }
      }
    },
  },
  plugins: [],
}
