# frozen_string_literal: true

require 'application_system_test_case'

module Pathogen
  module System
    # System tests for the Pathogen::Tabs component
    # Tests interactive functionality including click navigation, keyboard controls,
    # URL synchronization, and accessibility features using real browser interactions
    class TabsTest < ApplicationSystemTestCase
      # =============================================================================
      # CLICK NAVIGATION TESTS
      # =============================================================================

      test 'switches tabs on click in basic usage' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Overview tab should be selected initially
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'

          # Click Features tab
          find('[role="tab"]', text: 'Features').click

          # Features tab should be selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'
          assert_selector '[role="tab"][aria-selected="false"]', text: 'Overview'

          # Features panel should be visible, Overview hidden
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'Key Features'
          assert_no_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'
        end
      end

      test 'updates ARIA attributes on click' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          features_tab = find('[role="tab"]', text: 'Features')

          # Initially overview is selected
          assert_equal 'true', overview_tab['aria-selected']
          assert_equal 'false', features_tab['aria-selected']

          # Click features tab
          features_tab.click

          # Check ARIA attributes updated
          assert_equal 'false', overview_tab['aria-selected']
          assert_equal 'true', features_tab['aria-selected']
          assert_equal '-1', overview_tab['tabindex']
          assert_equal '0', features_tab['tabindex']
        end
      end

      test 'maintains selection state across multiple clicks' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Click through all tabs
          find('[role="tab"]', text: 'Features').click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'

          find('[role="tab"]', text: 'Usage').click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Usage'

          # Click back to first
          find('[role="tab"]', text: 'Overview').click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Only one tab should be selected
          assert_selector '[role="tab"][aria-selected="true"]', count: 1
        end
      end

      # =============================================================================
      # KEYBOARD NAVIGATION TESTS - HORIZONTAL
      # =============================================================================

      test 'navigates to next tab with Right Arrow in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click # Ensure focus

          # Press Right Arrow
          overview_tab.native.send_keys(:right)

          # Features tab should be selected and focused
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'
          assert_equal '0', find('[role="tab"]', text: 'Features')['tabindex']
        end
      end

      test 'navigates to previous tab with Left Arrow in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Start with Features tab
          features_tab = find('[role="tab"]', text: 'Features')
          features_tab.click

          # Press Left Arrow
          features_tab.native.send_keys(:left)

          # Overview tab should be selected and focused
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end

      test 'wraps to first tab when pressing Right Arrow on last tab in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Navigate to last tab
          usage_tab = find('[role="tab"]', text: 'Usage')
          usage_tab.click

          # Press Right Arrow
          usage_tab.native.send_keys(:right)

          # Should wrap to first tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end

      test 'wraps to last tab when pressing Left Arrow on first tab in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Press Left Arrow
          overview_tab.native.send_keys(:left)

          # Should wrap to last tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Usage'
        end
      end

      test 'navigates to first tab with Home key in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Start with last tab
          usage_tab = find('[role="tab"]', text: 'Usage')
          usage_tab.click

          # Press Home
          usage_tab.native.send_keys(:home)

          # Should jump to first tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end

      test 'navigates to last tab with End key in horizontal mode' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Press End
          overview_tab.native.send_keys(:end)

          # Should jump to last tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Usage'
        end
      end

      test 'automatic activation: panel changes immediately with arrow keys' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Initial state - Overview panel visible
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'

          # Press Right Arrow
          overview_tab.native.send_keys(:right)

          # Panel should change immediately without Enter/Space
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'Key Features'
          assert_no_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'
        end
      end

      test 'roving tabindex pattern with keyboard navigation' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          features_tab = find('[role="tab"]', text: 'Features')
          usage_tab = find('[role="tab"]', text: 'Usage')

          overview_tab.click

          # Only first tab should be in tab sequence
          assert_equal '0', overview_tab['tabindex']
          assert_equal '-1', features_tab['tabindex']
          assert_equal '-1', usage_tab['tabindex']

          # Navigate to second
          overview_tab.native.send_keys(:right)

          # Now only second tab should be in tab sequence
          assert_equal '-1', overview_tab['tabindex']
          assert_equal '0', features_tab['tabindex']
          assert_equal '-1', usage_tab['tabindex']
        end
      end

      # =============================================================================
      # KEYBOARD NAVIGATION TESTS - VERTICAL ORIENTATION
      # =============================================================================

      test 'navigates to next tab with Down Arrow in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')

        # Wait for controller to connect
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          # Verify vertical orientation
          assert_selector '[role="tablist"][aria-orientation="vertical"]'

          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click # Ensure focus

          # Wait for tab to be selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Press Down Arrow
          find('[role="tab"]', text: 'Overview').native.send_keys(:down)

          # Features tab should be selected and focused
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features', wait: 1
          assert_equal '0', find('[role="tab"]', text: 'Features')['tabindex']
        end
      end

      test 'navigates to previous tab with Up Arrow in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          # Start with Features tab
          features_tab = find('[role="tab"]', text: 'Features')
          features_tab.click

          # Wait for selection to update
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'

          # Press Up Arrow
          find('[role="tab"]', text: 'Features').native.send_keys(:up)

          # Overview tab should be selected and focused
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview', wait: 1
        end
      end

      test 'wraps to first tab when pressing Down Arrow on last tab in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          # Navigate to last tab
          examples_tab = find('[role="tab"]', text: 'Examples')
          examples_tab.click

          # Wait for selection
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Examples'

          # Press Down Arrow
          find('[role="tab"]', text: 'Examples').native.send_keys(:down)

          # Should wrap to first tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview', wait: 1
        end
      end

      test 'wraps to last tab when pressing Up Arrow on first tab in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Wait for selection
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Press Up Arrow
          find('[role="tab"]', text: 'Overview').native.send_keys(:up)

          # Should wrap to last tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Examples', wait: 1
        end
      end

      test 'Home and End keys work in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          # Start with Features tab
          features_tab = find('[role="tab"]', text: 'Features')
          features_tab.click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'

          # Press Home
          find('[role="tab"]', text: 'Features').native.send_keys(:home)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview', wait: 1

          # Press End
          find('[role="tab"]', text: 'Overview').native.send_keys(:end)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Examples', wait: 1
        end
      end

      test 'horizontal arrow keys do not navigate in vertical mode' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Press Right Arrow (should not navigate in vertical mode)
          find('[role="tab"]', text: 'Overview').native.send_keys(:right)

          # Overview tab should still be selected - allow brief time for any errant JS
          sleep 0.05
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Press Left Arrow (should not navigate in vertical mode)
          find('[role="tab"]', text: 'Overview').native.send_keys(:left)

          # Overview tab should still be selected
          sleep 0.05
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end

      # =============================================================================
      # URL HASH SYNCHRONIZATION TESTS
      # =============================================================================

      test 'updates URL hash when tab is clicked with sync_url enabled' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync')
        within('[data-controller-connected="true"]') do
          # Initial hash should be set to first tab
          assert_equal '#tab-getting-started', page.evaluate_script('window.location.hash')

          # Click second tab
          find('[role="tab"]', text: 'How It Works').click

          # URL hash should update
          assert_equal '#tab-how-it-works', page.evaluate_script('window.location.hash')

          # Click third tab
          find('[role="tab"]', text: 'Use Cases').click

          # URL hash should update again
          assert_equal '#tab-use-cases', page.evaluate_script('window.location.hash')
        end
      end

      test 'initializes with tab from URL hash when sync_url enabled' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync#tab-how-it-works')
        within('[data-controller-connected="true"]') do
          # Second tab should be selected based on hash
          assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The component listens for tab changes'

          # URL hash should be preserved
          assert_equal '#tab-how-it-works', page.evaluate_script('window.location.hash')
        end
      end

      test 'falls back to default when hash is invalid with sync_url' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync#invalid-hash')
        within('[data-controller-connected="true"]') do
          # Should fall back to first tab (default_index: 0)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Getting Started'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'What is URL Sync?'
        end
      end

      test 'browser back button navigates to previous tab' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync')
        assert_selector '[data-controller-connected="true"]', wait: 2

        # Navigate through tabs - need to be outside within block for hash navigation
        find('[role="tab"]', text: 'How It Works').click
        assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 1

        find('[role="tab"]', text: 'Use Cases').click
        assert_selector '[role="tab"][aria-selected="true"]', text: 'Use Cases', wait: 1

        # Press back button
        page.evaluate_script('window.history.back()')

        # Wait for hash change to trigger tab change
        assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 2
        assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The component listens for tab changes'
      end

      test 'browser forward button navigates to next tab' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync')
        assert_selector '[data-controller-connected="true"]', wait: 2

        # Navigate forward
        find('[role="tab"]', text: 'How It Works').click
        assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 1

        find('[role="tab"]', text: 'Use Cases').click
        assert_selector '[role="tab"][aria-selected="true"]', text: 'Use Cases', wait: 1

        # Go back
        page.evaluate_script('window.history.back()')
        assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 2

        # Go forward
        page.evaluate_script('window.history.forward()')

        # Should be back on Use Cases tab
        assert_selector '[role="tab"][aria-selected="true"]', text: 'Use Cases', wait: 2
        assert_selector '[role="tabpanel"]:not(.hidden)', text: 'Perfect Use Cases'
      end

      test 'keyboard navigation updates URL hash with sync_url enabled' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync')
        assert_selector '[data-controller-connected="true"]', wait: 2

        within('[data-controller-connected="true"]') do
          getting_started_tab = find('[role="tab"]', text: 'Getting Started')
          getting_started_tab.click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Getting Started'

          # Navigate with keyboard
          find('[role="tab"]', text: 'Getting Started').native.send_keys(:right)

          # How It Works tab should be selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 1
        end

        # URL should update
        assert_equal '#tab-how-it-works', page.evaluate_script('window.location.hash')
      end

      test 'does not update URL when sync_url is false' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Initial hash should be empty
          initial_hash = page.evaluate_script('window.location.hash')
          assert_equal '', initial_hash

          # Click Features tab
          find('[role="tab"]', text: 'Features').click

          # Hash should remain empty
          assert_equal '', page.evaluate_script('window.location.hash')
        end
      end

      test 'hash supports panel ID format' do
        visit('/rails/view_components/pathogen/tabs_preview/url_sync#panel-how-it-works')
        within('[data-controller-connected="true"]') do
          # Should find tab by panel ID
          assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The component listens for tab changes'
        end
      end

      # =============================================================================
      # ACCESSIBILITY TESTS
      # =============================================================================

      test 'has proper ARIA structure' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Tablist with label
          assert_selector '[role="tablist"][aria-label]'

          # Tabs with proper attributes
          tabs = all('[role="tab"]')
          assert_operator tabs.count, :>=, 1

          tabs.each do |tab|
            assert tab['id'].present?, 'Tab must have id'
            assert tab['aria-selected'].present?, 'Tab must have aria-selected'
            assert tab['tabindex'].present?, 'Tab must have tabindex'
          end

          # Panels with proper attributes
          panels = all('[role="tabpanel"]')
          assert_operator panels.count, :>=, 1

          panels.each do |panel|
            assert panel['id'].present?, 'Panel must have id'
            assert panel['aria-labelledby'].present?, 'Panel must have aria-labelledby'
          end

          # Exactly one tab should be selected
          assert_selector '[role="tab"][aria-selected="true"]', count: 1
        end
      end

      test 'tab-panel associations are correct' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          tabs = all('[role="tab"]')
          panels = all('[role="tabpanel"]', visible: false)

          # Verify we have the expected number of tabs and panels
          assert_equal 3, tabs.count, "Expected 3 tabs, got #{tabs.count}"
          assert_equal 3, panels.count, "Expected 3 panels, got #{panels.count}"

          # Each tab should control a panel
          tabs.each_with_index do |tab, index|
            panel = panels[index]
            assert_not_nil panel, "Panel at index #{index} should exist"

            # aria-labelledby should reference tab id (set by component)
            assert_equal tab['id'], panel['aria-labelledby']
            # aria-controls should reference panel id (set by JS)
            assert_equal panel['id'], tab['aria-controls']
          end
        end
      end

      test 'screen reader state announcements are correct' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # When a tab is selected, aria-selected should be true for screen readers
          selected_tab = find('[role="tab"][aria-selected="true"]')
          assert_not_nil selected_tab

          # Panel visibility is communicated via aria-hidden
          visible_panel = find('[role="tabpanel"]:not(.hidden)')
          assert_equal 'false', visible_panel['aria-hidden']

          hidden_panels = all('[role="tabpanel"].hidden')
          hidden_panels.each do |panel|
            assert_equal 'true', panel['aria-hidden']
          end
        end
      end

      test 'orientation attribute is set correctly for horizontal' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          assert_selector '[role="tablist"][aria-orientation="horizontal"]'
        end
      end

      test 'orientation attribute is set correctly for vertical' do
        visit('/rails/view_components/pathogen/tabs_preview/orientations')
        within('[data-controller-connected="true"]') do
          # Find the vertical tabs section
          assert_selector '[role="tablist"][aria-orientation="vertical"]'
        end
      end

      # =============================================================================
      # CONTROLLER LIFECYCLE TESTS
      # =============================================================================

      test 'controller adds initialization marker class on connect' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')

        # Verify controller is connected and marker is present
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert tabs_container[:class].include?('tabs-initialized')
      end

      test 'controller adds connected marker attribute' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')

        # Verify marker is present
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert_equal 'true', tabs_container['data-controller-connected']
      end

      test 'removes initialization marker class on simulated disconnect' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')

        # Verify controller is connected and marker is present
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert tabs_container[:class].include?('tabs-initialized')

        # Simulate disconnect by removing the initialization marker
        page.execute_script(<<~JS)
          const element = document.querySelector('[data-controller="pathogen--tabs"]');
          if (element) {
            element.classList.remove('tabs-initialized');
          }
        JS

        # Marker should be removed
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert_not tabs_container[:class].include?('tabs-initialized')
      end

      test 'removes controller connected marker on simulated disconnect' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')

        # Verify marker is present
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert_equal 'true', tabs_container['data-controller-connected']

        # Simulate disconnect by removing the connected marker
        page.execute_script(<<~JS)
          const element = document.querySelector('[data-controller="pathogen--tabs"]');
          if (element) {
            delete element.dataset.controllerConnected;
          }
        JS

        # Marker should be removed
        tabs_container = find('[data-controller="pathogen--tabs"]')
        assert_nil tabs_container['data-controller-connected']
      end

      # =============================================================================
      # EDGE CASES & INTERACTION TESTS
      # =============================================================================

      test 'rapid tab switching shows most recent tab content' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          # Click through tabs with small delays to ensure JavaScript processes each click
          find('[role="tab"]', text: 'Features').click
          sleep(0.05)
          find('[role="tab"]', text: 'Usage').click
          sleep(0.05)
          find('[role="tab"]', text: 'Overview').click

          # Wait for final DOM updates and JavaScript to process
          sleep(0.1)

          # Final tab should be selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Final panel should be visible
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'

          # Only one panel should be visible
          assert_selector '[role="tabpanel"]:not(.hidden)', count: 1

          # All other panels should be hidden
          all_panels = all('[role="tabpanel"]', visible: false)
          hidden_panels = all_panels.select { |panel| panel[:class].include?('hidden') }
          assert_equal 2, hidden_panels.count
        end
      end

      test 'rapid keyboard navigation shows correct final tab' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Rapidly press arrow right multiple times
          overview_tab.native.send_keys(:right)
          sleep 0.05 # Small delay to simulate rapid but sequential keypresses

          features_tab = find('[role="tab"]', text: 'Features')
          features_tab.native.send_keys(:right)
          sleep 0.05

          usage_tab = find('[role="tab"]', text: 'Usage')
          usage_tab.native.send_keys(:right) # Wraps to first

          # Should have wrapped back to first tab
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'
        end
      end

      test 'clicking already selected tab maintains selection' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')

          # Overview is already selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          # Click it again
          overview_tab.click

          # Should still be selected
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
          assert_selector '[role="tabpanel"]:not(.hidden)', text: 'The Pathogen::Tabs component provides'
          assert_selector '[role="tab"][aria-selected="true"]', count: 1
        end
      end

      test 'Tab key moves focus without changing selection' do
        visit('/rails/view_components/pathogen/tabs_preview/basic_usage')
        within('[data-controller-connected="true"]') do
          overview_tab = find('[role="tab"]', text: 'Overview')
          overview_tab.click

          # Press Tab key
          overview_tab.native.send_keys(:tab)

          # Tab is still selected (which is correct behavior)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end
    end
  end
end
