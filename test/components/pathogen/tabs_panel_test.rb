# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class TabsPanelTest < ViewComponent::TestCase
    test 'default panel' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |tabs|
        tabs.with_tab(selected: true, href: '#', text: 'Tab 1')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 2')
        tabs.with_tab(selected: false, href: '#', text: 'Tab 3')
      end
      render_inline(tabs_component)

      assert_selector 'nav[id="test_panel"]'
      assert_selector 'ul[role="tablist"]', count: 1
      assert_selector 'li', count: 3
      assert_selector 'a[class="inline-block p-4 text-primary-600 bg-slate-100 ' \
                      'rounded-t-lg active dark:bg-slate-800 dark:text-primary-500"]',
                      text: 'Tab 1'
      assert_selector 'a[class="inline-block p-4 rounded-t-lg hover:text-slate-600 ' \
                      'hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-slate-300"]',
                      text: 'Tab 2'
      assert_selector 'a[class="inline-block p-4 rounded-t-lg hover:text-slate-600 ' \
                      'hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-slate-300"]',
                      text: 'Tab 3'
    end

    test 'panel with counts' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |tabs|
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
      assert_selector 'span[class="bg-slate-300 text-slate-800 text-xs ' \
                      'font-medium ms-2 px-2 py-1 rounded-full dark:bg-slate-500 dark:text-slate-300"]',
                      text: '1'

      # Unselected tabs
      assert_selector 'span[class="bg-slate-100 text-slate-800 text-xs ' \
                      'font-medium ms-2 px-2 py-1 rounded-full dark:bg-slate-700 dark:text-slate-300"]',
                      text: '10'
      assert_selector 'span[class="bg-slate-100 text-slate-800 text-xs ' \
                      'font-medium ms-2 px-2 py-1 rounded-full dark:bg-slate-700 dark:text-slate-300"]',
                      text: '100'
    end
  end
end
