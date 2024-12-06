# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test for the TabsPanel component
  class TabsPanelTest < ViewComponent::TestCase
    test 'default panel' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel', test_selector: 'test_panel').tap do |tabs|
        tabs.with_tab(selected: true, href: '#', text: 'Tab 1')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 2')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 3')
      end
      render_inline(tabs_component)

      assert_selector 'nav[data-test-selector="test_panel"]'
      assert_selector 'ul[role="tablist"]', count: 1
      assert_selector 'li', count: 3
      assert_selector 'a[aria-current="page"][aria-selected="true"]', text: 'Tab 1'
      assert_selector 'a[aria-selected="false"]', text: 'Tab 2'
      assert_selector 'a[aria-selected="false"]', text: 'Tab 3'
    end

    test 'default panel with counts' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel', test_selector: 'test_panel').tap do |tabs|
        tabs.with_tab(selected: true, href: '#', text: 'Tab 1') do |tab|
          tab.with_count(count: 1)
        end
        tabs.with_tab(selected: false, href: '#', text: 'Tab 2') do |tab|
          tab.with_count(count: 10)
        end
        tabs.with_tab(selected: false, href: '#', text: 'Tab 3') do |tab|
          tab.with_count(count: 100)
        end
      end
      render_inline(tabs_component)

      # Selected tab
      assert_selector 'a[aria-selected="true"] span', text: '1'

      # Unselected tabs
      assert_selector 'a[aria-selected="false"] span', text: '10'
      assert_selector 'a[aria-selected="false"] span', text: '100'
    end

    test 'underline panel' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel', test_selector: 'test_panel',
                                               type: 'underline').tap do |tabs|
        tabs.with_tab(selected: true, href: '#', text: 'Tab 1')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 2')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 3')
      end
      render_inline(tabs_component)

      assert_selector 'nav[id="test_panel"]'
      assert_selector 'ul[role="tablist"]', count: 1
      assert_selector 'li', count: 3
      assert_selector 'a[aria-selected="true"]', text: 'Tab 1'
      assert_selector 'a[aria-selected="false"]', text: 'Tab 2'
      assert_selector 'a[aria-selected="false"]', text: 'Tab 3'
    end

    test 'underline panel with counts' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel', test_selector: 'test_panel',
                                               type: 'underline').tap do |tabs|
        tabs.with_tab(selected: true, href: '#', text: 'Tab 1') do |tab|
          tab.with_count(count: 1)
        end
        tabs.with_tab(selected: false, href: '#', text: 'Tab 2') do |tab|
          tab.with_count(count: 10)
        end
        tabs.with_tab(selected: false, href: '#', text: 'Tab 3') do |tab|
          tab.with_count(count: 100)
        end
      end
      render_inline(tabs_component)

      # Selected tab
      assert_selector 'a[aria-selected="true"] span', text: '1'

      # Unselected tabs
      assert_selector 'a[aria-selected="false"] span', text: '10'
      assert_selector 'a[aria-selected="false"] span', text: '100'
    end
  end
end
