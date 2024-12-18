module.exports = {
  darkMode: "class",
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/components/**/*",
    "./app/views/**/*.{erb,html}",
    "./node_modules/flowbite/**/*.js",
    "./test/components/previews/**/*",
    "./test/components/viral/system/**/*",
    "./embedded_gems/**/app/components/**/*.rb",
    "./embedded_gems/**/app/lib/**/*.rb",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#16a34a",
          50: "#f0fdf4",
          100: "#dcfce7",
          200: "#bbf7d0",
          300: "#86efac",
          400: "#4ade80",
          500: "#22c55e",
          600: "#16a34a",
          700: "#15803d",
          800: "#166534",
          900: "#14532d",
          950: "#052e16",
        },
      },
    },
  },
  plugins: [require("flowbite/plugin")],
};
