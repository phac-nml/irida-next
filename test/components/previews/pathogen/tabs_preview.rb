# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen::Tabs usage
  # Showcases accessibility features, lazy loading, and various configurations
  class TabsPreview < ViewComponent::Preview
    # @!group Tabs Component

    # @label Default
    # Three tabs with basic content to demonstrate default behavior
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def default
      render(Pathogen::Tabs.new(id: 'preview-tabs-default', label: 'Preview tabs')) do |tabs|
        tabs.with_tab(id: 'tab-1', label: 'First', selected: true)
        tabs.with_tab(id: 'tab-2', label: 'Second')
        tabs.with_tab(id: 'tab-3', label: 'Third')

        tabs.with_panel(id: 'panel-1', tab_id: 'tab-1') do
          tag.div(class: 'p-4') do
            tag.h3('First panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This is the content for the first tab. Click on other tabs to see different content.')
          end
        end

        tabs.with_panel(id: 'panel-2', tab_id: 'tab-2') do
          tag.div(class: 'p-4') do
            tag.h3('Second panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This is the content for the second tab. Use keyboard arrow keys to navigate between tabs.')
          end
        end

        tabs.with_panel(id: 'panel-3', tab_id: 'tab-3') do
          tag.div(class: 'p-4') do
            tag.h3('Third panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This is the content for the third tab. Try pressing Home and End keys to jump to first/last tabs.')
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label With Selection
    # Demonstrates tabs with a specific tab selected by default (second tab)
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def with_selection
      render(Pathogen::Tabs.new(
               id: 'preview-tabs-selection',
               label: 'Preview tabs',
               default_index: 1
             )) do |tabs|
        tabs.with_tab(id: 'tab-1', label: 'First')
        tabs.with_tab(id: 'tab-2', label: 'Second', selected: true)
        tabs.with_tab(id: 'tab-3', label: 'Third')

        tabs.with_panel(id: 'panel-1', tab_id: 'tab-1') do
          tag.div(class: 'p-4') do
            tag.p('First panel content')
          end
        end

        tabs.with_panel(id: 'panel-2', tab_id: 'tab-2') do
          tag.div(class: 'p-4') do
            tag.p('Second panel content (initially selected via default_index: 1)')
          end
        end

        tabs.with_panel(id: 'panel-3', tab_id: 'tab-3') do
          tag.div(class: 'p-4') do
            tag.p('Third panel content')
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label Single Tab
    # Edge case with only one tab
    def single_tab
      render(Pathogen::Tabs.new(id: 'preview-tabs-single', label: 'Single tab preview')) do |tabs|
        tabs.with_tab(id: 'tab-only', label: 'Only Tab', selected: true)

        tabs.with_panel(id: 'panel-only', tab_id: 'tab-only') do
          tag.div(class: 'p-4') do
            tag.p('This is the only panel. Keyboard navigation will wrap to the same tab.')
          end
        end
      end
    end

    # @label Many Tabs
    # Demonstrates tabs with many items
    def many_tabs
      render(Pathogen::Tabs.new(id: 'preview-tabs-many', label: 'Many tabs preview')) do |tabs|
        (1..8).each do |i|
          tabs.with_tab(id: "tab-#{i}", label: "Tab #{i}", selected: i == 1)

          tabs.with_panel(id: "panel-#{i}", tab_id: "tab-#{i}") do
            tag.div(class: 'p-4') do
              tag.h3("Content for Tab #{i}", class: 'text-lg font-semibold mb-2') +
                tag.p("Panel #{i} content goes here.")
            end
          end
        end
      end
    end

    # @label With Rich Content
    # Demonstrates tabs with more complex HTML content
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def with_rich_content
      render(Pathogen::Tabs.new(id: 'preview-tabs-rich', label: 'Rich content tabs')) do |tabs|
        tabs.with_tab(id: 'tab-overview', label: 'Overview', selected: true)
        tabs.with_tab(id: 'tab-details', label: 'Details')
        tabs.with_tab(id: 'tab-settings', label: 'Settings')

        tabs.with_panel(id: 'panel-overview', tab_id: 'tab-overview') do
          tag.div(class: 'p-4 space-y-4') do
            tag.h3('Project Overview', class: 'text-xl font-bold text-slate-900 dark:text-white') +
              tag.p('This panel contains rich HTML content with multiple elements.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.ul(class: 'list-disc list-inside space-y-2') do
                tag.li('Feature 1: Accessible keyboard navigation') +
                  tag.li('Feature 2: ARIA compliant') +
                  tag.li('Feature 3: Dark mode support')
              end
          end
        end

        tabs.with_panel(id: 'panel-details', tab_id: 'tab-details') do
          tag.div(class: 'p-4 space-y-4') do
            tag.h3('Details', class: 'text-xl font-bold text-slate-900 dark:text-white') +
              tag.div(class: 'space-y-2') do
                tag.div(class: 'flex justify-between') do
                  tag.dt('Status:', class: 'font-semibold') +
                    tag.dd('Active', class: 'text-green-600')
                end +
                  tag.div(class: 'flex justify-between') do
                    tag.dt('Created:', class: 'font-semibold') +
                      tag.dd('2025-10-16', class: 'text-slate-600 dark:text-slate-400')
                  end
              end
          end
        end

        tabs.with_panel(id: 'panel-settings', tab_id: 'tab-settings') do
          tag.div(class: 'p-4') do
            tag.h3('Settings', class: 'text-xl font-bold text-slate-900 dark:text-white mb-4') +
              tag.div(class: 'space-y-3') do
                tag.label(class: 'flex items-center gap-2') do
                  tag.input(type: 'checkbox', checked: true) +
                    tag.span('Enable notifications')
                end +
                  tag.label(class: 'flex items-center gap-2') do
                    tag.input(type: 'checkbox') +
                      tag.span('Auto-save changes')
                  end
              end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label With Right Content
    # Demonstrates tabs with right-aligned content area
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def with_right_content
      render(Pathogen::Tabs.new(id: 'preview-tabs-right', label: 'Tabs with right content')) do |tabs|
        tabs.with_tab(id: 'tab-1', label: 'First', selected: true)
        tabs.with_tab(id: 'tab-2', label: 'Second')
        tabs.with_tab(id: 'tab-3', label: 'Third')

        tabs.with_right_content do
          tag.button('Action', class: 'button button-primary')
        end

        tabs.with_panel(id: 'panel-1', tab_id: 'tab-1') do
          tag.div(class: 'p-4') { tag.p('First panel with right-aligned action button') }
        end

        tabs.with_panel(id: 'panel-2', tab_id: 'tab-2') do
          tag.div(class: 'p-4') { tag.p('Second panel') }
        end

        tabs.with_panel(id: 'panel-3', tab_id: 'tab-3') do
          tag.div(class: 'p-4') { tag.p('Third panel') }
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label Accessibility Features
    # Demonstrates accessibility features including ARIA attributes and keyboard navigation hints
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def accessibility_features
      render(Pathogen::Tabs.new(id: 'preview-tabs-a11y', label: 'Accessibility demonstration')) do |tabs|
        tabs.with_tab(id: 'tab-keyboard', label: 'Keyboard', selected: true)
        tabs.with_tab(id: 'tab-screen-reader', label: 'Screen Reader')
        tabs.with_tab(id: 'tab-focus', label: 'Focus Management')

        tabs.with_panel(id: 'panel-keyboard', tab_id: 'tab-keyboard') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Keyboard Navigation', class: 'text-lg font-semibold mb-2') +
              tag.p('This tabs component supports full keyboard navigation:', class: 'mb-2') +
              tag.ul(class: 'list-disc list-inside space-y-1 text-sm') do
                tag.li("#{tag.kbd('→')} and #{tag.kbd('←')} to navigate between tabs") +
                  tag.li("#{tag.kbd('Home')} to jump to first tab") +
                  tag.li("#{tag.kbd('End')} to jump to last tab") +
                  tag.li("#{tag.kbd('Tab')} to move focus in and out of tab list")
              end
          end
        end

        tabs.with_panel(id: 'panel-screen-reader', tab_id: 'tab-screen-reader') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Screen Reader Support', class: 'text-lg font-semibold mb-2') +
              tag.p('ARIA attributes provide screen reader support:', class: 'mb-2') +
              tag.ul(class: 'list-disc list-inside space-y-1 text-sm') do
                tag.li('role="tablist" on container') +
                  tag.li('role="tab" on each tab button') +
                  tag.li('role="tabpanel" on each content panel') +
                  tag.li('aria-selected indicates active tab') +
                  tag.li('aria-labelledby links panels to tabs') +
                  tag.li('aria-controls links tabs to panels')
              end
          end
        end

        tabs.with_panel(id: 'panel-focus', tab_id: 'tab-focus') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Focus Management', class: 'text-lg font-semibold mb-2') +
              tag.p('The component implements roving tabindex pattern:', class: 'mb-2') +
              tag.ul(class: 'list-disc list-inside space-y-1 text-sm') do
                tag.li('Only active tab is in tab sequence (tabindex="0")') +
                  tag.li('Inactive tabs have tabindex="-1"') +
                  tag.li('Arrow keys move focus and select automatically') +
                  tag.li('Visible focus ring on focused tab')
              end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label Lazy Loading
    # Demonstrates Turbo Frame lazy loading with loading indicators
    # This preview shows how panels can load content on demand when tabs are clicked
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def lazy_loading
      render(Pathogen::Tabs.new(id: 'preview-tabs-lazy', label: 'Lazy loading demonstration')) do |tabs|
        tabs.with_tab(id: 'tab-overview-lazy', label: 'Overview', selected: true)
        tabs.with_tab(id: 'tab-details-lazy', label: 'Details')
        tabs.with_tab(id: 'tab-settings-lazy', label: 'Settings')

        # First panel: Preloaded content (no lazy loading)
        tabs.with_panel(id: 'panel-overview-lazy', tab_id: 'tab-overview-lazy') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Overview panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This panel loads immediately with the page.', class: 'text-slate-700 dark:text-slate-300') +
              tag.p('The other tabs use Turbo Frame lazy loading to defer content until clicked.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end

        # Second panel: Lazy loaded with Turbo Frame
        tabs.with_panel(id: 'panel-details-lazy', tab_id: 'tab-details-lazy') do
          # In a real implementation, this would have src pointing to an actual endpoint
          # For preview purposes, we show the structure with a mock loading state
          tag.turbo_frame(
            id: 'details-frame',
            loading: 'lazy',
            class: 'block'
          ) do
            tag.div(class: 'p-4 space-y-3') do
              tag.div(class: 'flex items-center gap-3') do
                tag.div(class: 'animate-spin h-5 w-5 border-2 border-primary-500 border-t-transparent rounded-full') +
                  tag.p('Loading details...', class: 'text-slate-600 dark:text-slate-400')
              end +
                tag.p('In a real implementation, this would show a loading spinner while content fetches.',
                      class: 'text-sm text-slate-500 dark:text-slate-500')
            end
          end
        end

        # Third panel: Lazy loaded with Turbo Frame
        tabs.with_panel(id: 'panel-settings-lazy', tab_id: 'tab-settings-lazy') do
          tag.turbo_frame(
            id: 'settings-frame',
            loading: 'lazy',
            class: 'block'
          ) do
            tag.div(class: 'p-4 space-y-3') do
              tag.div(class: 'flex items-center gap-3') do
                tag.div(class: 'animate-spin h-5 w-5 border-2 border-primary-500 border-t-transparent rounded-full') +
                  tag.p('Loading settings...', class: 'text-slate-600 dark:text-slate-400')
              end +
                tag.p('Click back to Details tab to see cached content (no refetch).',
                      class: 'text-sm text-slate-500 dark:text-slate-500')
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label With URL Sync
    # Demonstrates tabs with URL hash synchronization for bookmarkable tabs
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def with_url_sync
      render(Pathogen::Tabs.new(
               id: 'preview-tabs-url-sync',
               label: 'URL synchronized tabs',
               sync_url: true
             )) do |tabs|
        tabs.with_tab(id: 'tab-overview', label: 'Overview', selected: true)
        tabs.with_tab(id: 'tab-details', label: 'Details')
        tabs.with_tab(id: 'tab-settings', label: 'Settings')

        tabs.with_panel(id: 'panel-overview', tab_id: 'tab-overview') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Overview panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This tab is synchronized with the URL hash. Try refreshing the page or using browser back/forward buttons.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('The URL will update when you click different tabs.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end

        tabs.with_panel(id: 'panel-details', tab_id: 'tab-details') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Details panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This tab can be bookmarked and shared via URL.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('Check the browser address bar to see the hash change.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end

        tabs.with_panel(id: 'panel-settings', tab_id: 'tab-settings') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Settings panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('URL synchronization works with keyboard navigation too.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('Try using arrow keys and watch the URL update.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @label Vertical Orientation
    # Demonstrates tabs with vertical orientation
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vertical
      render(Pathogen::Tabs.new(
               id: 'preview-tabs-vertical',
               label: 'Vertical tabs',
               orientation: :vertical
             )) do |tabs|
        tabs.with_tab(id: 'tab-1-vertical', label: 'First', selected: true)
        tabs.with_tab(id: 'tab-2-vertical', label: 'Second')
        tabs.with_tab(id: 'tab-3-vertical', label: 'Third')

        tabs.with_panel(id: 'panel-1-vertical', tab_id: 'tab-1-vertical') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('First panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('This demonstrates vertical tab orientation.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('Use Up/Down arrow keys to navigate between tabs.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end

        tabs.with_panel(id: 'panel-2-vertical', tab_id: 'tab-2-vertical') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Second panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('Vertical tabs are useful for sidebars and narrow layouts.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('The keyboard navigation adapts to the orientation.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end

        tabs.with_panel(id: 'panel-3-vertical', tab_id: 'tab-3-vertical') do
          tag.div(class: 'p-4 space-y-3') do
            tag.h3('Third panel content', class: 'text-lg font-semibold mb-2') +
              tag.p('Home and End keys still work for jumping to first/last tabs.',
                    class: 'text-slate-700 dark:text-slate-300') +
              tag.p('All accessibility features are preserved in vertical mode.',
                    class: 'text-slate-600 dark:text-slate-400 text-sm')
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # @!endgroup
  end
end
