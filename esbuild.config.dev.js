// esbuild Development Configuration
// This configuration handles JavaScript bundling for development
// with inline source maps, watch mode, and unminified output for debugging.
// CSS is handled separately by Tailwind CLI for better performance and compatibility.

import * as esbuild from "esbuild";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Build context for development with watch mode
const ctx = await esbuild.context({
  // Entry points for JavaScript only (CSS handled by Tailwind CLI)
  entryPoints: ["app/javascript/irida.js"],

  // Output configuration
  bundle: true,
  format: "esm",
  outdir: "app/assets/builds",

  // Development-specific settings
  sourcemap: "inline",
  minify: false,

  // Target modern browsers (ES2020)
  target: "es2020",

  // Logging
  logLevel: "info",

  // Path resolution
  absWorkingDir: __dirname,
  preserveSymlinks: false,

  // Conditions for package exports (needed for Tailwind CSS 4.0)
  conditions: ["style"],

  // Path aliases for clean imports
  alias: {
    controllers: path.resolve(__dirname, "app/javascript/controllers"),
    utilities: path.resolve(__dirname, "app/javascript/utilities"),
  },

  // Bundle settings for development
  splitting: false, // Disabled for simpler dev builds
  chunkNames: "[name]",

  // Tree-shaking at basic level
  treeShaking: true,

  // Asset names configuration
  assetNames: "[name]",
  entryNames: "[name]",
});

// Watch mode for automatic rebuilds
await ctx.watch();

console.log("esbuild development server started - watching for changes...");
