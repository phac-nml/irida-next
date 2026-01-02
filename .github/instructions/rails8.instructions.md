---
applyTo: "**/*.rb"
---
# Rails 8 Coding Standards

## Framework Best Practices
- Use GoodJob for background job processing
- Follow Rails conventions for naming and file organization
- Use ActiveModel attributes API for defining model attributes
- Use Rails built-in testing tools (Minitest) for all test cases
- Use PostgreSQL for development and production environments

## Rails Controllers
- Keep controllers thin, focused on HTTP concerns
- Use strong parameters for all user input
- Prefer redirect_to with notice/alert over render for form submissions
- Use before_action filters for authentication and shared setup
- Respond to appropriate formats (HTML, Turbo Stream, JSON)

## Rails Models
- Use Rails validations extensively to ensure data integrity
- Add custom validation methods when built-in validators aren't sufficient
- Keep model callbacks minimal and consider service objects for complex logic
- Use scopes for common queries that return ActiveRecord::Relation
- Implement proper associations with dependent options

## Rails Views
- Use partials for reusable components
- Keep logic out of views, use helpers or view objects when needed
- Follow Turbo conventions for dynamic page updates
- Use content_for to define regions of content in layouts
- Use Rails helpers appropriately (form_with, link_to, etc.)

## Import Maps
- Use Import Maps for JavaScript dependencies
- Keep import map entries in `config/importmap.rb`
- Import JavaScript modules using ESM imports
- Pin external dependencies with specific versions
- Organize JavaScript code in modular files under app/javascript

## ActiveJob and GoodJob
- Create dedicated job classes that inherit from ApplicationJob
- Keep jobs idempotent when possible
- Use meaningful queue names based on purpose
- Set appropriate retry behavior for each job
- Use perform_later for background processing
