/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/javascript/pages/**/*.{vue,js,ts}', // Vue and JS/TS files in pages folder
    './app/javascript/components/**/*.{vue,js,ts}', // if you have a components folder
    './app/views/**/*.{html,erb}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
