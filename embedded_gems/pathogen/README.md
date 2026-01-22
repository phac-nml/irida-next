# Pathogen ViewComponents

A comprehensive ViewComponents library for Rails applications, featuring accessible, internationalized UI components with integrated Stimulus controllers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pathogen_view_components'
```

And then execute:

```bash
bundle install
```

## JavaScript Integration

Pathogen ViewComponents includes Stimulus controllers that provide interactive behavior for components like tabs, tooltips, and datepickers.

### Automatic Setup (Rails Engine)

When used as a Rails Engine (the default for IRIDA Next), the JavaScript integration is automatic:

1. **Importmap Auto-Registration**: The engine automatically registers its importmap configuration with your Rails application. No manual importmap.rb changes are needed.

2. **Controller Auto-Registration**: Import the entry point in your `app/javascript/application.js`:

```javascript
import "@hotwired/turbo-rails"
import "controllers"
import "pathogen_view_components"  // Auto-registers all Pathogen controllers
```

That's it! All Pathogen Stimulus controllers are now registered and ready to use.

### Available Controllers

Pathogen provides four Stimulus controllers:

- **`pathogen--tabs`**: W3C ARIA-compliant tabs with keyboard navigation and URL hash syncing
- **`pathogen--tooltip`**: Simple tooltips with Flowbite integration (temporary dependency)
- **`pathogen--datepicker--input`**: Date input with calendar popup and validation
- **`pathogen--datepicker--calendar`**: Interactive calendar widget with keyboard navigation

### Verifying Controller Registration

To verify that Pathogen controllers are registered correctly:

1. **Check Importmap Registration**: Visit `/rails/importmap` in your browser and search for "pathogen". You should see:
   - `pathogen_view_components` entry point
   - `pathogen-controllers/pathogen/*` controller paths

2. **Enable Stimulus Debug Mode**: Open your browser console and run:
   ```javascript
   window.Stimulus.debug = true
   ```

3. **Refresh the Page**: You should see registration logs for:
   - `pathogen--tabs`
   - `pathogen--tooltip`
   - `pathogen--datepicker--input`
   - `pathogen--datepicker--calendar`

4. **Inspect Registered Controllers**: In the browser console:
   ```javascript
   application.controllers
   ```

### JavaScript Dependencies

Pathogen controllers depend on:

- **@hotwired/stimulus** ^3.0.0 (required)
- **uuid** ^13.0.0 (required for tabs controller)
- **flowbite** ^3.1.2 (required for tooltip - temporary dependency, planned for removal)
- **@hotwired/turbo-rails** ^8.0.0 (peer dependency)

These dependencies should be available in your application's importmap or package manager.

## External Gem Usage (Future)

When extracted as a standalone gem, integration remains simple:

```ruby
# Gemfile
gem 'pathogen_view_components'
```

```javascript
// app/javascript/application.js
import "pathogen_view_components"
```

The engine automatically merges its importmap with your application's importmap. No manual configuration required.

## Troubleshooting

### Controllers Not Registering

**Problem**: Pathogen controllers are not appearing in Stimulus debug output.

**Solutions**:
1. Verify the import in `app/javascript/application.js`:
   ```javascript
   import "pathogen_view_components"
   ```

2. Check the importmap at `/rails/importmap` for pathogen entries.

3. Clear Rails caches:
   ```bash
   bin/rails tmp:clear
   ```

4. Restart your Rails server.

### Import Resolution Errors

**Problem**: Browser console shows 404 errors for pathogen controller imports.

**Solutions**:
1. Verify the engine's importmap is registered:
   ```bash
   bin/rails runner "puts Rails.application.config.importmap.paths.grep(/pathogen/)"
   ```
   Should output: `embedded_gems/pathogen/config/importmap.rb`

2. Check cache sweepers are configured in development mode.

3. Clear browser cache or use incognito mode.

### Controller Identifiers Not Working

**Problem**: Components using `data-controller="pathogen--tabs"` are not connecting.

**Solutions**:
1. Enable Stimulus debug mode: `window.Stimulus.debug = true`

2. Check browser console for controller registration logs.

3. Verify the component template uses the correct identifier:
   - Tabs: `pathogen--tabs`
   - Tooltip: `pathogen--tooltip`
   - Datepicker: `pathogen--datepicker--input` and `pathogen--datepicker--calendar`

### Flowbite Errors

**Problem**: Tooltip controller throws "Flowbite not found" errors.

**Solutions**:
1. Ensure Flowbite is imported in your application.js:
   ```javascript
   import "flowbite"
   ```

2. Note: Flowbite is a temporary dependency and will be removed in a future version.

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bin/rails test
```

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the MIT License.
