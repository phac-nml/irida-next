import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import globals from "globals";
import prettierConfig from "eslint-config-prettier";

export default defineConfig([
  // Apply recommended rules
  js.configs.recommended,

  // Global ignores (similar to .prettierignore)
  {
    ignores: [
      "node_modules/**",
      "vendor/**",
      "coverage/**",
      "tmp/**",
      "log/**",
      "storage/**",
      "public/assets/**",
      "app/assets/builds/**",
      ".devenv/**",
      "docs-site/**", // Docusaurus has its own linting
      "vendor/javascript/**",
    ],
  },

  // Application JavaScript files (Stimulus controllers, utilities)
  {
    name: "app-javascript",
    files: [
      "app/javascript/**/*.js",
      "embedded_gems/**/app/javascript/**/*.js",
    ],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.browser,
        // Hotwire/Turbo globals
        Turbo: "readonly",
        // Flowbite globals
        Tooltip: "readonly",
        Modal: "readonly",
        Drawer: "readonly",
        Dropdown: "readonly",
        Tabs: "readonly",
        Collapse: "readonly",
        Carousel: "readonly",
        Dismiss: "readonly",
        Popover: "readonly",
        // Node.js globals used in some files
        process: "readonly",
      },
    },
    rules: {
      "no-console": ["warn", { allow: ["error", "warn"] }],
      "prefer-const": "error",
      "no-var": "error",
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
    },
  },

  // Build configuration and Node.js files
  {
    name: "node-files",
    files: ["app/assets/config/**/*.js", "*.config.js", "*.config.mjs"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
      },
    },
    rules: {
      "no-console": "off",
    },
  },

  // JavaScript tests (Node test runner + jsdom globals)
  {
    name: "js-tests",
    files: ["test/javascript/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
        ...globals.browser,
      },
    },
  },

  // Disable Prettier-conflicting rules (must be last)
  prettierConfig,
]);
