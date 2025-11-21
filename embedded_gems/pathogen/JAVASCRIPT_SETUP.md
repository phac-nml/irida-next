# Pathogen JavaScript Controllers Setup

This document explains how to set up Pathogen's Stimulus controllers in your Rails application.

## Overview

Pathogen includes Stimulus controllers for interactive components:
- `pathogen--tabs` - Tab navigation with keyboard support
- `pathogen--tooltip` - Tooltip display functionality
- `pathogen--datepicker--input` - Date input field with validation
- `pathogen--datepicker--calendar` - Visual calendar date picker

## Setup Requirements

### 1. Asset Pipeline Configuration

Ensure the gem's JavaScript assets are included in your asset pipeline.

**Pathogen Engine Configuration** (already configured in `lib/pathogen/view_components/engine.rb`):
```ruby
# Add gem's JavaScript directory to asset paths
config.assets.paths << root.join('app/assets/javascripts')
```

### 2. Asset Manifest

Add Pathogen's JavaScript files to your asset precompilation manifest.

**In your `app/assets/config/manifest.js`**:
```javascript
//= link_tree ../../../embedded_gems/pathogen/app/assets/javascripts .js
```

Or for a standalone gem installation:
```javascript
//= link_tree path/to/pathogen/app/assets/javascripts .js
```

### 3. Importmap Configuration

Pin the Pathogen controllers in your `config/importmap.rb` explicitly (recommended for engine/gem compatibility):

```ruby
# Pathogen gem controllers (embedded or external gem)
# Only pin controller files (*_controller.js); utilities use relative imports
pathogen_controllers_path = Pathogen::ViewComponents::Engine.root.join('app/assets/javascripts/pathogen/controllers')
Dir.glob(pathogen_controllers_path.join('**/*_controller.js')).each do |file|
  # Use Pathname for reliable relative path calculation across different OS
  relative_path = Pathname.new(file).relative_path_from(pathogen_controllers_path)
  name = relative_path.to_s.delete_suffix('.js')
  pin "controllers/pathogen/#{name}", to: "pathogen/controllers/#{name}.js", preload: false
end
```

### 4. Dependencies

Pathogen controllers depend on these libraries (ensure they're pinned in your importmap):

```ruby
pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js'
pin 'uuid' # @13.0.0 or compatible
```

**Required by**:
- `tooltip_controller.js` - Uses Flowbite's `Tooltip` class
- `datepicker/calendar_controller.js` - Uses Flowbite's `Dropdown` class and `uuid`
- `datepicker/input_controller.js` - Uses `uuid`

### 5. Stimulus Auto-Loading

Pathogen controllers integrate with Stimulus's lazy-loading system automatically.

**Your `app/javascript/controllers/index.js` should include**:
```javascript
import { application } from "./application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"

lazyLoadControllersFrom("controllers", application)
```

This will automatically discover and register controllers with the `pathogen--` prefix.

## Controller Naming Convention

Controllers are registered with the `pathogen--` prefix based on their file paths:

| File Path | Stimulus Identifier |
|-----------|-------------------|
| `pathogen/controllers/tabs_controller.js` | `pathogen--tabs` |
| `pathogen/controllers/tooltip_controller.js` | `pathogen--tooltip` |
| `pathogen/controllers/datepicker/input_controller.js` | `pathogen--datepicker--input` |
| `pathogen/controllers/datepicker/calendar_controller.js` | `pathogen--datepicker--calendar` |

## Usage in Components

Controllers are automatically available when using Pathogen ViewComponents:

```erb
<%= render Pathogen::Tabs::Component.new do |tabs| %>
  <%# Uses data-controller="pathogen--tabs" internally %>
  <% tabs.with_tab(label: "Tab 1") do %>
    Content 1
  <% end %>
<% end %>
```

## Verification

After setup, verify controllers are registered:

1. Start your Rails server
2. Open browser developer console
3. Check registered controllers:
   ```javascript
   window.Stimulus.application.controllers.forEach(c => console.log(c.identifier))
   ```
4. Look for: `pathogen--tabs`, `pathogen--tooltip`, `pathogen--datepicker--input`, `pathogen--datepicker--calendar`

## Troubleshooting

### Controllers not registering
- Verify asset paths are configured in engine.rb
- Check importmap includes pathogen controllers
- Ensure Stimulus lazy-loading is enabled
- Check browser console for import errors

### Asset precompilation errors
- Ensure manifest.js includes pathogen JavaScript directory
- Verify file paths are correct
- Check that `config.assets.paths` includes gem's JavaScript directory

### Import errors
- Verify Flowbite and uuid are pinned in importmap
- Check import statements in controller files match pinned names
- Ensure relative imports (`./utils`, `./constants`) resolve correctly

## For Standalone Gem Installation

When Pathogen is moved to its own repository, consuming applications will need to:

1. Add to Gemfile: `gem 'pathogen_view_components'`
2. Add manifest link (step 2 above)
3. Add importmap pins (step 3 above)
4. Pin dependencies (step 4 above)

No changes to ViewComponent usage or `data-controller` attributes will be required.

## File Structure

```
pathogen/
└── app/
    └── assets/
        └── javascripts/
            └── pathogen/
                └── controllers/
                    ├── tabs_controller.js (657 lines)
                    ├── tooltip_controller.js (26 lines)
                    └── datepicker/
                        ├── input_controller.js (378 lines)
                        ├── calendar_controller.js (713 lines)
                        ├── utils.js (26 lines)
                        └── constants.js (51 lines)
```

## Dependencies Version Compatibility

- Rails 8.0+
- Stimulus 3.x
- Flowbite 3.1.2+
- uuid 13.0.0+
- importmap-rails

---

**Last Updated**: 2025-11-17
**Pathogen Version**: 0.0.1
