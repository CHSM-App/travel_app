/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // ── Warm Sand — mirrors frontend/lib/core/theme/app_colors.dart ──
        sand:   { DEFAULT: '#faf7f2', soft: '#f6eee6', border: '#ece4d9' },
        ink:    { DEFAULT: '#292420', dark: '#1c1813', soft: '#8a7f73' },
        clay:   { DEFAULT: '#b5651d', dark: '#92500f', light: '#c98a4b', soft: '#f6eee6' },
        success:     '#4d7c0f', successSoft: '#ecf4de',
        warning:     '#c2860b', warningSoft: '#f7edd6',
        danger:      '#b91c1c', dangerSoft:  '#f7e3e0',
        info:        '#2563eb', infoSoft:    '#e4eafb',
        star:        '#ca8a04',
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        body:    ['"Inter"', 'system-ui', 'sans-serif'],
        mono:    ['"JetBrains Mono"', 'monospace'],
      },
      boxShadow: {
        soft:  '0 1px 2px rgba(41,36,32,0.04), 0 14px 34px -20px rgba(41,36,32,0.18)',
        card:  '0 24px 56px -30px rgba(41,36,32,0.26)',
        phone: '0 50px 100px -44px rgba(41,36,32,0.4)',
      },
      borderRadius: { '4xl': '2rem' },
      animation: {
        fadeUp:  'fadeUp 0.7s cubic-bezier(0.16,1,0.3,1) forwards',
        marquee: 'marquee 38s linear infinite',
        floaty:  'floaty 7s ease-in-out infinite',
      },
      keyframes: {
        fadeUp:  { from: { opacity: 0, transform: 'translateY(22px)' }, to: { opacity: 1, transform: 'translateY(0)' } },
        marquee: { '0%': { transform: 'translateX(0)' }, '100%': { transform: 'translateX(-50%)' } },
        floaty:  { '0%,100%': { transform: 'translateY(0)' }, '50%': { transform: 'translateY(-10px)' } },
      },
    },
  },
  plugins: [],
}
