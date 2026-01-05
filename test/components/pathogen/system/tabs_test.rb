# frozen_string_literal: true

require 'application_system_test_case'

module Pathogen
  module System
    # Browser-level tests for the Pathogen::Tabs component previews.
    # The previews render several variants that exercise the Stimulus controller,
    # ARIA attributes, and optional URL-synchronisation behaviour.
    class TabsTest < ApplicationSystemTestCase
      BASIC_PREVIEW_PATH = '/rails/view_components/pathogen/tabs/basic_usage'
      ORIENTATION_PREVIEW_PATH = '/rails/view_components/pathogen/tabs/orientations'
      URL_SYNC_PREVIEW_PATH = '/rails/view_components/pathogen/tabs/url_sync'

      test 'clicking a tab shows its panel and updates aria state' do
        visit BASIC_PREVIEW_PATH
        wait_for_tabs('simple-tabs')

        within_tabs('simple-tabs') do
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
          assert_selector '[role="tabpanel"][aria-labelledby="tab-overview"][aria-hidden="false"]'

          click_on 'Features'
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'
          assert_selector '#panel-features', visible: :visible
          assert_selector '#panel-overview', visible: :hidden
        end
      end

      test 'roving tabindex keeps only the active tab focusable' do
        visit BASIC_PREVIEW_PATH
        wait_for_tabs('simple-tabs')

        within_tabs('simple-tabs') do
          overview = find('[role="tab"]', text: 'Overview')
          features = find('[role="tab"]', text: 'Features')
          usage = find('[role="tab"]', text: 'Usage')

          assert_equal '0', overview['tabindex']
          assert_equal '-1', features['tabindex']
          assert_equal '-1', usage['tabindex']

          features.click

          assert_equal '-1', overview['tabindex']
          assert_equal '0', features['tabindex']
          assert_equal '-1', usage['tabindex']
        end
      end

      test 'horizontal arrow keys cycle through tabs and wrap around' do
        visit ORIENTATION_PREVIEW_PATH
        wait_for_tabs('horizontal-tabs')

        within_tabs('horizontal-tabs') do
          overview = find('[role="tab"]', text: 'Overview')
          overview.click

          overview.native.send_keys(:right)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'

          find('[role="tab"]', text: 'Documentation').click
          find('[role="tab"]', text: 'Documentation').native.send_keys(:right)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Examples'

          find('[role="tab"]', text: 'Examples').native.send_keys(:right)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'
        end
      end

      test 'home and end key navigation is supported' do
        visit ORIENTATION_PREVIEW_PATH
        wait_for_tabs('horizontal-tabs')

        within_tabs('horizontal-tabs') do
          overview = find('[role="tab"]', text: 'Overview')
          overview.click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          overview.native.send_keys(:right)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Features'

          find('[role="tab"]', text: 'Features').native.send_keys(:home)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Overview'

          find('[role="tab"]', text: 'Features').native.send_keys(:end)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Examples'
        end
      end

      test 'vertical arrow keys navigate up and down without reacting to left/right' do
        visit ORIENTATION_PREVIEW_PATH
        wait_for_tabs('vertical-tabs')

        within_tabs('vertical-tabs') do
          assert_selector '[role="tablist"][aria-orientation="vertical"]'

          dashboard = find('[role="tab"]', text: 'Dashboard')
          dashboard.click
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Dashboard'

          dashboard.native.send_keys(:down)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Settings'

          settings = find('[role="tab"]', text: 'Settings')
          settings.native.send_keys(:down)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Profile'

          profile = find('[role="tab"]', text: 'Profile')
          profile.native.send_keys(:down)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Notifications'

          notifications = find('[role="tab"]', text: 'Notifications')
          notifications.native.send_keys(:down)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Dashboard'

          dashboard = find('[role="tab"]', text: 'Dashboard')
          dashboard.native.send_keys(:up)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Notifications'

          notifications = find('[role="tab"]', text: 'Notifications')
          notifications.native.send_keys(:left)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Notifications'

          notifications.native.send_keys(:right)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Notifications'
        end
      end

      test 'sync_url updates the hash when tabs are clicked' do
        visit URL_SYNC_PREVIEW_PATH
        wait_for_tabs('url-sync-demo')

        within_tabs('url-sync-demo') do
          assert_equal '#tab-getting-started', page.evaluate_script('window.location.hash')

          find('[role="tab"]', text: 'How It Works').click
          assert_equal '#tab-how-it-works', page.evaluate_script('window.location.hash')

          find('[role="tab"]', text: 'Use Cases').click
          assert_equal '#tab-use-cases', page.evaluate_script('window.location.hash')
        end
      end

      test 'sync_url honours the hash when loading the page' do
        visit "#{URL_SYNC_PREVIEW_PATH}#tab-how-it-works"
        wait_for_tabs('url-sync-demo')

        within_tabs('url-sync-demo') do
          assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works'
          assert_selector '#panel-how-it-works', visible: :visible
        end
      end

      test 'sync_url falls back to the default tab when the hash is unknown' do
        visit "#{URL_SYNC_PREVIEW_PATH}#unknown-tab"
        wait_for_tabs('url-sync-demo')

        within_tabs('url-sync-demo') do
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Getting Started'
          assert_selector '#panel-getting-started', visible: :visible
        end
      end

      test 'keyboard navigation with sync_url updates the hash' do
        visit URL_SYNC_PREVIEW_PATH
        wait_for_tabs('url-sync-demo')

        within_tabs('url-sync-demo') do
          # Start with Getting Started tab (should be selected by default)
          assert_selector '[role="tab"][aria-selected="true"]', text: 'Getting Started'

          # Send right arrow key to navigate to next tab
          find('[role="tab"][aria-selected="true"]').native.send_keys(:right)
        end

        # Wait for tab selection and debounced hash update
        assert_selector '[role="tab"][aria-selected="true"]', text: 'How It Works', wait: 2

        # Wait a bit more for the debounced hash update
        sleep(0.2)
        assert_equal '#tab-how-it-works', page.evaluate_script('window.location.hash')
      end

      test 'tabs expose controller connection markers for progressive enhancement' do
        visit BASIC_PREVIEW_PATH
        assert_selector '#simple-tabs-container.tabs-initialized[data-controller-connected="true"]', wait: 10
      end

      test 'tabs and panels remain paired via aria attributes' do
        visit BASIC_PREVIEW_PATH
        wait_for_tabs('simple-tabs')

        within_tabs('simple-tabs') do
          tabs = all('[role="tab"]')
          panels = all('[role="tabpanel"]', visible: :all)

          assert_equal tabs.size, panels.size

          tabs.each_with_index do |tab, index|
            panel = panels[index]
            assert_equal tab['id'], panel['aria-labelledby']
            assert_equal panel['id'], tab['aria-controls']
          end
        end
      end

      private

      def wait_for_tabs(id)
        assert_selector "##{id}-container[data-controller-connected=\"true\"]", wait: 10
      end

      def within_tabs(id, &)
        within("##{id}-container", &)
      end
    end
  end
end
