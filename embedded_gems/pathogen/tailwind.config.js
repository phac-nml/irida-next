/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/components/**/*.erb",
    "./app/components/**/*.html",
    "./app/components/**/*.rb",
    "./app/lib/**/*.rb",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
