// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  corePlugins: {
    preflight: false, // disable Tailwind's reset
  },
  content: ['./src/**/*.{js,jsx,ts,tsx}', './{docs,blog}/**/*.{md,mdx}'], // my markdown stuff is in ../docs, not /src
  darkMode: ['class', '[data-theme="dark"]'], // hooks into docusaurus' dark mode settings
  theme: {
    extend: {
      colors: {
        // Light Theme
        'great-memories-primary': '#4250af',
        'great-memories-bg': '#f9f8fb',
        'great-memories-fg': 'black',
        'great-memories-gray': '#F6F6F4',

        // Dark Theme
        'great-memories-dark-primary': '#adcbfa',
        'great-memories-dark-bg': '#000000',
        'great-memories-dark-fg': '#e5e7eb',
        'great-memories-dark-gray': '#111111',
      },
    },
  },
  plugins: [],
};
