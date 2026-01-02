---
applyTo: "**/*.js,**/importmap.rb"
---
# Import Maps Guidelines

## Core Concepts
- Import Maps allow using modern JavaScript modules without a bundler
- Reference external modules directly with standardized module specifiers
- Pin dependencies to specific versions or CDN URLs
- Keep JavaScript source organized in modular files
- Works perfectly with Turbo and Stimulus in Rails applications

## Configuration Best Practices
- Define all imports in `config/importmap.rb`
- Pin external libraries to specific versions for stability
- Include all dependencies required by your application
- Consider using vendor directory for critical dependencies
- Use semantic versioning when pinning dependencies

## Directory Structure
- Organize JavaScript files in `app/javascript` directory
- Group related functionality in subdirectories (e.g., `controllers`, `utilities`)
- Keep Stimulus controllers in `app/javascript/controllers`
- Use index files to export components from directories
- Follow module naming conventions consistently

## Module Usage Patterns
- Import modules using standard ESM syntax: `import { Controller } from "stimulus"`
- Avoid global namespace pollution by keeping imports scoped
- Use named exports for better code discoverability
- Consider module patterns for organizing complex functionality
- Lazy load modules for performance when appropriate

## Example Configuration
```ruby
# config/importmap.rb
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stimulus-use", to: "https://cdn.jsdelivr.net/npm/stimulus-use@0.52.0/dist/stimulus-use.min.js"
pin "local-time", to: "https://ga.jspm.io/npm:local-time@2.1.0/app/assets/javascripts/local-time.js"
```

## Implementation Examples
```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
import { createConsumer } from "@rails/actioncable"

// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Hello, Stimulus!", this.element)
  }
}
```

## Integration with Turbo and Stimulus
- Import Stimulus and Turbo at the application root
- Register Stimulus controllers automatically with `stimulus-loading`
- Load ActionCable for WebSocket communication when needed
- Import specific npm packages for additional functionality
- Keep initialization code in the main application.js file

## Performance Considerations
- Use `preload: true` for critical dependencies
- Implement code splitting for rarely used features
- Consider lazy-loading for components not needed on initial load
- Use CDNs for popular libraries to leverage browser caching
- Evaluate module size when choosing dependencies

## Security Best Practices
- Pin to specific versions to prevent supply chain attacks
- Consider subresource integrity when loading from external sources
- Regularly update dependencies for security patches
- Use Content Security Policy headers to restrict sources
- Validate external scripts before including them in your application
