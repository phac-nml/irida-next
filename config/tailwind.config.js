module.exports = {
  darkMode: "class",
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/components/**/*.{erb,html}",
    "./app/components/**/*",
    "./node_modules/flowbite/**/*.js",
    "./test/components/previews/**/*",
    "./test/components/viral/system/**/*",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#f0fdf4",
          100: "#dcfce7",
          200: "#bbf7d0",
          300: "#6ee7b7",
          400: "#4ade80",
          500: "#22c55e",
          600: "#16a34a",
          700: "#15803d",
          800: "#166534",
          900: "#365314",
        },
      },
    },
  },
  plugins: [require("flowbite/plugin")],
};
