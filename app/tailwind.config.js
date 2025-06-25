/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f8f8f2',
          100: '#e0e0d1',
          200: '#c2b280',
          300: '#b2a162',
          400: '#f92672', // hot pink
          500: '#fd971f', // orange
          600: '#66d9ef', // cyan
          700: '#a6e22e', // green
          800: '#282a36', // dark bg
          900: '#1a1a1a', // darker bg
        },
        retroYellow: '#fff200',
        retroBlue: '#00eaff',
        retroPink: '#ff4ecd',
        retroGreen: '#39ff14',
        retroBg: '#22223b',
        retroPanel: '#272640',
        retroAccent: '#f8f8f2',
      },
      fontFamily: {
        retro: ["'Press Start 2P'", 'monospace'],
      },
      animation: {
        'bounce-slow': 'bounce 2s infinite',
        'pulse-slow': 'pulse 3s infinite',
      }
    },
  },
  plugins: [],
} 