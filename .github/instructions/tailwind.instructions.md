---
applyTo: "**/*.css,**/*.scss,**/*.erb,**/*.html.erb"
---
# Tailwind CSS v4 Guidelines

## Configuration (CSS-Based)
- This project uses **Tailwind CSS v4** with CSS-based configuration — there is no `tailwind.config.js`
- All theme customization is done via `@theme` blocks in `app/assets/stylesheets/application.tailwind.css`
- Use `@theme` to define custom colors, spacing, breakpoints, and other design tokens as CSS variables
- Use `@plugin` to load plugins (e.g., `@plugin "flowbite/plugin"`)
- Use `@source` to register additional content paths for class detection (e.g., `@source "../../../node_modules/flowbite/**/*.js"`)
- Use `@custom-variant` for custom variant definitions (e.g., dark mode)
- CSS is built with `@tailwindcss/cli` — see `package.json` scripts

## Custom Utilities
- Use `@utility` directive to define custom utility classes (replaces v3 `@layer utilities`)
- Custom utilities defined with `@utility` work with all variants (hover, dark, responsive, etc.)
- Use `@apply` inside `@utility` blocks to compose from existing utilities
- Use `@layer base` for base/reset styles and `@layer components` for component-level styles
- Avoid `@layer utilities` for new utilities — use `@utility` instead

## Layout Patterns
- Use Flexbox and Grid for modern layouts
- Implement proper responsive design with Tailwind's breakpoint prefixes (sm:, md:, lg:, xl:)
- Follow a mobile-first approach for all components
- Use container class with proper max-width constraints
- Implement proper spacing using Tailwind's spacing scale

## Component Styling
- Use consistent padding and margin scales
- Implement proper text styling with Tailwind's typography classes
- Create reusable component patterns with consistent styling
- Use Tailwind's transition utilities for interactive elements
- Apply proper hover/focus states for interactive elements

## Form Styling
- Style form elements consistently with Tailwind classes
- Implement proper validation state styling
- Use appropriate input sizing and padding
- Style buttons consistently across the application
- Implement accessible form designs with proper labels and focus states

## Deprecated Utilities (v4.2+)
- Use `inset-s-*` / `inset-e-*` instead of `start-*` / `end-*` for inset-inline positioning
- Use `outline-hidden` instead of `outline-none` (when hiding outlines while keeping the outline property)
- Use `shadow-xs` instead of `shadow-sm` for the smallest shadow scale (v3 `shadow-sm` → v4 `shadow-xs`)
- Use `ring-3` instead of `ring` if you need a 3px ring width (v4 default ring is 1px)
- Place the `!` important modifier at the end of the class name (e.g., `flex!` not `!flex`)

## Performance
- Tailwind v4 automatically tree-shakes unused styles — no manual purge configuration needed
- CSS is compiled and minified via `@tailwindcss/cli` (`pnpm run build:css`)
- Use `@source not` to exclude directories from scanning if build performance is a concern

## Integration with Hotwire
- Add appropriate Tailwind transitions to Turbo Frame updates
- Use Tailwind classes with Stimulus controllers for dynamic styling
- Apply consistent animations to Turbo Stream updates
- Ensure proper styling persistence across Turbo navigation
- Implement responsive designs that work well with Hotwire
