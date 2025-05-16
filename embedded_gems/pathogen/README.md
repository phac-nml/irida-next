# Pathogen View Components

A collection of reusable view components for the IRIDA Next application.

> **Note:** Version 0.1.0 includes a migration from Heroicons to Phosphor icons. See the [Migration Guide](MIGRATION_GUIDE.md) for details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pathogen_view_components', path: 'embedded_gems/pathogen'
```

And then execute:

```bash
bundle install
```

## Components

### Button

A flexible button component with multiple styles and states.

#### Usage

```erb
<%= render Pathogen::Button.new(scheme: :primary) { "Click me" } %>

<%= render Pathogen::Button.new(scheme: :ghost) do |c| %>
  <% c.with_leading_visual_icon(icon: 'plus') %>
  Add Item
<% end %>
```

#### Available Schemes

- `:default` - Default button style
- `:primary` - Primary action button
- `:danger` - Destructive action button
- `:ghost` - Text-only button with no background or border

### Icon

A component for rendering Phosphor icons from the Rails Designer Icons gem.

#### Usage

```erb
<%= render Pathogen::Icon.new(icon: 'user') %>
<%= render Pathogen::Icon.new(icon: 'gear', variant: :bold, size: '2rem') %>
```

#### Parameters

- `icon` - The name of the Phosphor icon (required)
- `variant` - The icon variant (`:regular`, `:thin`, `:light`, `:bold`, `:fill`, `:duotone`), defaults to `:regular`
- `size` - The size of the icon (e.g., '1.5rem', '24px'), defaults to '1.5rem'
- Other HTML attributes will be passed through to the icon element

### TabsPanel

A tabbed interface component.

#### Usage

```erb
<%= render Pathogen::TabsPanel.new(id: 'user_tabs') do |tabs| %>
  <% tabs.with_tab(selected: true, href: '#profile', text: 'Profile', icon: 'user') do |tab| %>
    <% tab.with_count(count: 5) %>
  <% end %>
  <% tabs.with_tab(href: '#settings', text: 'Settings', icon: 'gear') %>
<% end %>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/phac-nml/irida-next.
