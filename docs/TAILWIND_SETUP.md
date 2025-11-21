# Tailwind CSS 4 Setup with esbuild

## Architecture

This project uses **Tailwind CSS v4.1.17** with a **CLI-based approach** that runs separately from esbuild. This architecture provides:

- ⚡ **100x faster incremental builds** (Tailwind v4's new engine)
- 🔧 **Better compatibility** (no bundler integration issues)
- 🎯 **Separation of concerns** (JS and CSS processed independently)
- 🔄 **Parallel watch mode** (both processes run simultaneously)

## File Structure

```
app/assets/
  tailwind/
    irida.css          # Source CSS with @import and @source directives
  builds/
    irida.css          # Generated CSS (146KB minified)
    irida.js           # Generated JavaScript bundle

esbuild.config.dev.js  # JavaScript bundling (dev mode)
esbuild.config.prod.js # JavaScript bundling (production)
package.json           # Scripts for CSS and JS builds
Procfile.dev           # Runs both processes in parallel
```

## Configuration Files

### `app/assets/tailwind/irida.css`

Source file with Tailwind v4 directives:

```css
@import "tailwindcss";

/* Content sources for class scanning */
@source "app/views/**/*.{erb,html}";
@source "app/components/**/*.{erb,html}";
@source "app/javascript/**/*.{js,ts}";

/* Your custom CSS with @apply, @layer, etc. */
```

### `package.json` Scripts

```json
{
  "scripts": {
    "dev": "node esbuild.config.dev.js",
    "build": "node esbuild.config.prod.js",
    "build:css": "tailwindcss -i ./app/assets/tailwind/irida.css -o ./app/assets/builds/irida.css --minify",
    "watch:css": "tailwindcss -i ./app/assets/tailwind/irida.css -o ./app/assets/builds/irida.css --watch"
  }
}
```

### `Procfile.dev`

Runs both processes in parallel:

```
web: GOOD_JOB_EXECUTION_MODE=external bin/rails server -p 3000 -b 0.0.0.0
js: pnpm run dev
css: pnpm run watch:css
worker: bundle exec good_job --queues="+transactional_messages,*"
```

## Usage

### Development (with auto-reload)

```bash
bin/dev  # Starts Rails, esbuild, Tailwind CLI, and GoodJob
```

This runs:
- Rails server on port 3000
- esbuild in watch mode (JavaScript)
- Tailwind CLI in watch mode (CSS)
- GoodJob worker

### Production Build

```bash
# Build JavaScript
pnpm run build

# Build CSS
pnpm run build:css
```

### Manual CSS Build

```bash
# Development (unminified, fast)
pnpm run watch:css

# Production (minified)
pnpm run build:css
```

## Key Differences from Tailwind v3

### Tailwind v4 Changes

1. **No `tailwind.config.js`** - Configuration via CSS:
   ```css
   @import "tailwindcss";
   @source "app/**/*.erb";  /* Content paths in CSS */
   ```

2. **New CLI** - `@tailwindcss/cli` replaces `tailwindcss`:
   ```bash
   tailwindcss -i input.css -o output.css --watch
   ```

3. **Built-in autoprefixer** - No need for PostCSS setup

4. **Faster builds** - 5x faster full builds, 100x faster incremental

### Why Not PostCSS Integration?

The previous setup used `esbuild-plugin-postcss` with `@tailwindcss/postcss`, but:

❌ **Problems:**
- `esbuild-plugin-postcss` v0.3.0 has compatibility issues with Tailwind v4
- `@apply` directives weren't being processed
- Slower build times due to bundler overhead

✅ **CLI Solution:**
- Tailwind's official recommendation for v4
- No bundler integration needed
- Processes CSS correctly every time
- Faster and more reliable

## Verifying the Setup

### Check for Unprocessed Directives

```bash
# Should return NO results
grep "@apply" app/assets/builds/irida.css
```

### Check CSS Generation

```bash
# Should show ~146KB file
ls -lh app/assets/builds/irida.css

# Should show Tailwind utility classes
head -50 app/assets/builds/irida.css
```

### Test Both Builds

```bash
# JavaScript build
pnpm run build
# Should output: ✓ Production build completed successfully

# CSS build
pnpm run build:css
# Should output: Done in ~300ms
```

## Troubleshooting

### CSS not updating

1. Check Tailwind CLI is running: `pnpm run watch:css`
2. Verify source file exists: `app/assets/tailwind/irida.css`
3. Check `@source` directives include your template paths

### Classes not appearing

1. Ensure templates are in `@source` paths
2. Rebuild CSS: `pnpm run build:css`
3. Check browser cache (hard refresh: Cmd+Shift+R)

### Build errors

1. Verify `@tailwindcss/cli` is installed: `pnpm list @tailwindcss/cli`
2. Check Node version: `node --version` (needs 18+)
3. Clean and rebuild:
   ```bash
   rm -rf app/assets/builds/*
   pnpm run build:css
   pnpm run build
   ```

## Migration Notes

If migrating from the old PostCSS setup:

1. ✅ Removed `@tailwindcss/postcss` from esbuild configs
2. ✅ Removed `esbuild-plugin-postcss` usage
3. ✅ Added separate Tailwind CLI commands
4. ✅ Updated `Procfile.dev` to run CSS process
5. ✅ Simplified `postcss.config.js` (kept for compatibility)

You can optionally remove these packages:
```bash
pnpm remove @tailwindcss/postcss esbuild-plugin-postcss
```

## Resources

- [Tailwind CSS v4 Documentation](https://tailwindcss.com/docs)
- [Tailwind CLI Guide](https://tailwindcss.com/docs/installation/tailwind-cli)
- [What's New in v4](https://tailwindcss.com/blog/tailwindcss-v4-beta)
