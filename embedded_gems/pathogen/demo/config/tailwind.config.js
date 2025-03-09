module.exports = {
  darkMode: "class",
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  plugins: [require("@tailwindcss/typography")],
};
