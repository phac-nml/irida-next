---
applyTo: "**/*.css,**/*.scss,**/*.erb,**/*.html.erb"
---
# Tailwind CSS Guidelines

## Configuration
- Use `tailwind.config.js` for theme customization and extensions
- Extend default Tailwind configuration rather than overriding it
- Configure content paths to include all relevant template files
- Set up proper Tailwind plugins for additional functionality
- Define consistent color palette and typography within theme

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

## Custom Components
- Create custom components by composing Tailwind utility classes
- Extract repeating patterns to reusable components
- Use @apply sparingly and only for highly reused patterns
- Document custom component patterns in comments
- Follow consistent naming conventions for custom components

## Performance Optimization
- Use Tailwind's JIT mode for optimal CSS bundle size
- Purge unused styles in production builds
- Consider extracting critical CSS for improved page load performance
- Optimize responsive images with proper sizing and formats
- Use preload for critical assets

## Integration with Hotwire
- Add appropriate Tailwind transitions to Turbo Frame updates
- Use Tailwind classes with Stimulus controllers for dynamic styling
- Apply consistent animations to Turbo Stream updates
- Ensure proper styling persistence across Turbo navigation
- Implement responsive designs that work well with Hotwire
