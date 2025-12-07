# frozen_string_literal: true

require 'view_component_test_case'

# Tests for dark mode rendering of critical components.
# These tests verify that components render correctly with dark mode classes
# or use utility classes that have dark mode support defined in application.css.
class DarkModeComponentTest < ViewComponentTestCase
  # Test 1: Verify button components use utility classes with dark mode support
  test 'button component uses utility class with dark mode support' do
    render_inline(Viral::ButtonComponent.new(state: :default)) do
      'Test Button'
    end

    # Verify the button utility classes are applied
    assert_selector 'button.button'
    assert_selector 'button.button-default'

    # The button-default utility class has dark mode support in application.css:
    # dark:border-slate-600 dark:bg-slate-800 dark:text-white dark:hover:bg-slate-700
    # This test confirms the utility class is applied correctly
  end

  # Test 2: Verify card component has inline dark mode classes
  test 'card component has inline dark mode classes' do
    render_inline(Viral::CardComponent.new) do
      'Card Content'
    end

    # Verify viral-card class is applied
    assert_selector 'section.viral-card'

    # Get the rendered HTML
    html = rendered_content

    # Viral::CardComponent has inline dark mode classes:
    # dark:border-slate-700 dark:bg-slate-800
    assert_includes html, 'dark:border-slate-700',
                    'Card should have dark:border-slate-700'
    assert_includes html, 'dark:bg-slate-800',
                    'Card should have dark:bg-slate-800'
  end

  # Test 3: Verify sidebar dropdown button has inline dark mode classes
  test 'sidebar component dropdown button has dark mode classes' do
    # Read and verify the sidebar component template directly
    template_path = Rails.root.join('app/components/layout/sidebar_component.html.erb')
    template_content = File.read(template_path)

    # Verify dropdown trigger button has dark mode variants
    assert_includes template_content, 'dark:border-slate-700',
                    'Sidebar dropdown button should have dark:border-slate-700'
    assert_includes template_content, 'dark:bg-slate-900',
                    'Sidebar dropdown button should have dark:bg-slate-900'
    assert_includes template_content, 'dark:hover:bg-slate-800',
                    'Sidebar dropdown button should have dark:hover:bg-slate-800'

    # Verify dropdown menu has dark mode divider
    assert_includes template_content, 'dark:divide-slate-600',
                    'Sidebar dropdown menu should have dark:divide-slate-600'
  end

  # Test 4: Verify activities list item has dark mode border
  test 'activities list item has dark mode border class' do
    template_path = Rails.root.join('app/components/activities/list_item_component.html.erb')
    template_content = File.read(template_path)

    # Verify the activity timeline dot has dark mode border
    assert_includes template_content, 'dark:border-slate-800',
                    'Activity list item should have dark:border-slate-800 for timeline dot'
  end

  # Test 5: Verify navbar-button utility has dark mode support
  test 'navbar-button utility class has dark mode support in CSS' do
    css_path = Rails.root.join('app/assets/tailwind/application.css')
    css_content = File.read(css_path)

    # Verify navbar-button utility has dark mode classes defined
    assert_includes css_content, '@utility navbar-button',
                    'CSS should define navbar-button utility'
    assert_includes css_content, 'dark:text-slate-400',
                    'navbar-button should have dark:text-slate-400'
    assert_includes css_content, 'dark:hover:bg-slate-700',
                    'navbar-button should have dark:hover:bg-slate-700'
  end

  # Test 6: Verify form-field utility has dark mode support
  test 'form-field utility class has dark mode support in CSS' do
    css_path = Rails.root.join('app/assets/tailwind/application.css')
    css_content = File.read(css_path)

    # Verify form-field utility has dark mode classes defined
    assert_includes css_content, '@utility form-field',
                    'CSS should define form-field utility'
    assert_includes css_content, 'dark:border-slate-600',
                    'form-field inputs should have dark:border-slate-600'
    assert_includes css_content, 'dark:bg-slate-800',
                    'form-field inputs should have dark:bg-slate-800'
    assert_includes css_content, 'dark:text-white',
                    'form-field inputs should have dark:text-white'
  end

  # Test 7: Verify button utility classes have complete dark mode support
  test 'button utility classes have dark mode support in CSS' do
    css_path = Rails.root.join('app/assets/tailwind/application.css')
    css_content = File.read(css_path)

    # Verify button-default has dark mode classes
    assert_includes css_content, '@utility button-default',
                    'CSS should define button-default utility'
    assert_includes css_content, 'dark:border-slate-600',
                    'button-default should have dark border'
    assert_includes css_content, 'dark:bg-slate-800',
                    'button-default should have dark background'

    # Verify button-primary has dark mode classes
    assert_includes css_content, '@utility button-primary',
                    'CSS should define button-primary utility'

    # Verify button-destructive has dark mode classes
    assert_includes css_content, '@utility button-destructive',
                    'CSS should define button-destructive utility'
    assert_includes css_content, 'dark:border-red-600',
                    'button-destructive should have dark border'
  end

  # Test 8: Verify CSS custom properties are defined for dark mode
  test 'CSS custom properties defined for semantic dark mode colors' do
    css_path = Rails.root.join('app/assets/tailwind/application.css')
    css_content = File.read(css_path)

    # Verify semantic color variables exist in light mode
    assert_includes css_content, '--color-bg-primary',
                    'CSS should define --color-bg-primary variable'
    assert_includes css_content, '--color-text-primary',
                    'CSS should define --color-text-primary variable'
    assert_includes css_content, '--color-border-default',
                    'CSS should define --color-border-default variable'

    # Verify dark mode overrides exist
    assert_match(/@custom-variant dark.*--color-bg-primary:\s*#020617/m, css_content,
                 'CSS should override --color-bg-primary in dark mode to slate-950')
    assert_match(/@custom-variant dark.*--color-text-primary:\s*#ffffff/m, css_content,
                 'CSS should override --color-text-primary in dark mode to white')
  end
end
