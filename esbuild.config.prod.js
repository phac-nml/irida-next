// esbuild Production Configuration
// This configuration handles JavaScript bundling for production
// with separate source maps, code splitting, minification, and aggressive optimization.
// CSS is handled separately by Tailwind CLI for better performance and compatibility.

import * as esbuild from 'esbuild';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Build configuration for production
await esbuild.build({
  // Entry points for JavaScript only (CSS handled by Tailwind CLI)
  entryPoints: [
    'app/javascript/irida.js',
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
