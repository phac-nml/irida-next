// PostCSS Configuration
// Processes CSS with Tailwind CSS 4.0 and Autoprefixer plugins
// Used by esbuild via esbuild-plugin-postcss
//
// Note: Tailwind CSS 4.0 uses a new @import-based syntax.
// The tailwindcss plugin processes the @import "tailwindcss" directive
// in app/assets/tailwind/application.css

export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
