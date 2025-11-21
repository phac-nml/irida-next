// esbuild Production Configuration
// This configuration handles JavaScript and CSS bundling for production
// with separate source maps, code splitting, minification, and aggressive optimization.

import * as esbuild from 'esbuild';
import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
const postcssPlugin = require('esbuild-plugin-postcss').default;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Build configuration for production
await esbuild.build({
  // Entry points for JavaScript and CSS
  entryPoints: [
    'app/javascript/application.js',
    'app/assets/tailwind/application.css',
  ],

  // Output configuration
  bundle: true,
  format: 'esm',
  outdir: 'app/assets/builds',

  // Production-specific settings
  sourcemap: 'external', // Separate .map files
  minify: true,

  // Target modern browsers (ES2020)
  target: 'es2020',

  // Remove debug code
  drop: ['console', 'debugger'],

  // Logging (warnings only for cleaner CI output)
  logLevel: 'warning',

  // Path resolution
  absWorkingDir: __dirname,
  preserveSymlinks: false,

  // Conditions for package exports (needed for Tailwind CSS 4.0)
  conditions: ['style'],

  // Path aliases for clean imports
  alias: {
    controllers: path.resolve(__dirname, 'app/javascript/controllers'),
    utilities: path.resolve(__dirname, 'app/javascript/utilities'),
  },

  // Plugins
  plugins: [
    postcssPlugin({
      // PostCSS will use postcss.config.js for Tailwind CSS 4.0 processing
      postcssPlugin: [],
    }),
  ],

  // Code splitting for vendor bundles (better caching)
  splitting: true,
  chunkNames: '[name]-[hash]',

  // Aggressive tree-shaking for production
  treeShaking: true,

  // Asset and entry names with cache busting
  assetNames: '[name]-[hash]',
  entryNames: '[name]',

  // Generate metafile for bundle analysis
  metafile: true,
}).then((result) => {
  console.log('✓ Production build completed successfully');

  // Optional: Log bundle sizes
  if (result.metafile) {
    console.log('\nBundle analysis:');
    for (const [file, info] of Object.entries(result.metafile.outputs)) {
      const sizeKB = (info.bytes / 1024).toFixed(2);
      console.log(`  ${file}: ${sizeKB} KB`);
    }
  }
}).catch((error) => {
  console.error('✗ Production build failed:', error);
  process.exit(1);
});
