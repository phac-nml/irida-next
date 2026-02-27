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

## DataGrid Component

Pathogen includes a lightweight, accessible DataGrid component for rendering tabular data with optional sticky columns.

### Basic Usage

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows, caption: "Samples") do |grid| %>
  <% grid.with_column("ID", key: :id, width: 120) %>
  <% grid.with_column("Name", key: :name, width: 240) %>
<% end %>
```

### Custom Cell Rendering

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows) do |grid| %>
  <% grid.with_column("Name") { |row| tag.strong(row[:name]) } %>
<% end %>
```

### Sticky Columns

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows, sticky_columns: 1) do |grid| %>
  <% grid.with_column("ID", key: :id, width: 120) %>
  <% grid.with_column("Name", key: :name, width: 240) %>
<% end %>
```

Sticky columns require a width (numeric values become `px`) or an explicit `sticky_left:` offset.

### Fill Constrained Containers

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows, fill_container: true) do |grid| %>
  <% grid.with_column("ID", key: :id, width: 120) %>
  <% grid.with_column("Name", key: :name) %>
<% end %>
```

Use `fill_container: true` when the grid is inside a flex layout with bounded height and should scroll internally.

### Extension Slots

DataGrid provides several slots for extending functionality:

#### Empty State

Display custom content when no rows are present:

```erb
<%= render Pathogen::DataGridComponent.new(rows: []) do |grid| %>
  <% grid.with_empty_state do %>
    <p>No data available</p>
  <% end %>
  <% grid.with_column("ID", key: :id) %>
<% end %>
```

#### Metadata Warning

Show warnings or notices above the table:

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows) do |grid| %>
  <% grid.with_metadata_warning do %>
    <div role="status" aria-live="polite">
      <%= viral_alert { "Some columns have been hidden" } %>
    </div>
  <% end %>
  <% grid.with_column("ID", key: :id) %>
<% end %>
```

#### Live Region

Add screen reader announcements for dynamic updates:

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows) do |grid| %>
  <% grid.with_live_region do %>
    <div role="status" aria-live="polite" aria-atomic="true"></div>
  <% end %>
  <% grid.with_column("ID", key: :id) %>
<% end %>
```

#### Footer

Add custom content below the table:

```erb
<%= render Pathogen::DataGridComponent.new(rows: @rows) do |grid| %>
  <% grid.with_column("ID", key: :id) %>
  <% grid.with_footer do %>
    <%= render Viral::Pagy::FullComponent.new(pagy: @pagy) %>
  <% end %>
<% end %>
```

## JavaScript Integration

Pathogen ViewComponents includes Stimulus controllers that provide interactive behavior for components like tabs and tooltips.

### Automatic Setup (Rails Engine)

When used as a Rails Engine (the default for IRIDA Next), the JavaScript integration requires one line of code plus importmap pins:

1. **Importmap Registration**: Add the Pathogen pins to your application's `config/importmap.rb`:

```ruby
pin 'pathogen_view_components', to: 'pathogen_view_components.js'
pin_all_from 'embedded_gems/pathogen/app/assets/javascripts/pathogen_view_components',
  under: 'pathogen_view_components'
```

2. **Controller Registration**: Register Pathogen controllers in your `app/javascript/controllers/index.js`:

```javascript
import { application } from "controllers/application";
import { registerPathogenControllers } from "pathogen_view_components";

// Register Pathogen controllers (required before lazy loading)
registerPathogenControllers(application);

import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading";
lazyLoadControllersFrom("controllers", application);
```

**Important**: Register Pathogen controllers _before_ calling `lazyLoadControllersFrom()` to prevent auto-load conflicts.

That's it! All Pathogen Stimulus controllers are now registered and ready to use.

### Available Controllers

Pathogen provides two Stimulus controllers:

- **`pathogen--tabs`**: W3C ARIA-compliant tabs with keyboard navigation and URL hash syncing
- **`pathogen--tooltip`**: Simple tooltips with Flowbite integration (temporary dependency)

### Verifying Controller Registration

To verify that Pathogen controllers are registered correctly:

1. **Check Importmap Registration**: Visit `/rails/importmap` in your browser and search for "pathogen". You should see:
   - `pathogen_view_components` entry point
   - `pathogen_view_components/pathogen/*` controller paths

2. **Enable Stimulus Debug Mode**: Open your browser console and run:

   ```javascript
   window.Stimulus.debug = true;
   ```

3. **Refresh the Page**: You should see registration logs for:
   - `pathogen--tabs`
   - `pathogen--tooltip`

4. **Inspect Registered Controllers**: In the browser console:
   ```javascript
   application.controllers;
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

```ruby
# config/importmap.rb
pin 'pathogen_view_components', to: 'pathogen_view_components.js'
pin_all_from 'embedded_gems/pathogen/app/assets/javascripts/pathogen_view_components',
  under: 'pathogen_view_components'
```

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application";
import { registerPathogenControllers } from "pathogen_view_components";

registerPathogenControllers(application);
```

Pathogen does not auto-register its importmap pins. Ensure the host application pins the Pathogen entrypoint and controllers.

## Troubleshooting

### Controllers Not Registering

**Problem**: Pathogen controllers are not appearing in Stimulus debug output.

**Solutions**:

1. Verify the registration in `app/javascript/controllers/index.js`:

   ```javascript
   import { registerPathogenControllers } from "pathogen_view_components";
   registerPathogenControllers(application);
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

### Flowbite Errors

**Problem**: Tooltip controller throws "Flowbite not found" errors.

**Solutions**:

1. Ensure Flowbite is imported in your application.js:

   ```javascript
   import "flowbite";
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
