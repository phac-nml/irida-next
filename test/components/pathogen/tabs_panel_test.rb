# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class TabsPanelTest < ViewComponent::TestCase
    test 'basic navigation panel' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Home', href: '/home', selected: true)
        nav.with_tab(id: 'nav-2', text: 'Profile', href: '/profile')
        nav.with_tab(id: 'nav-3', text: 'Settings', href: '/settings')
      end
      render_inline(tabs_component)

      # Navigation container
      assert_selector 'nav[id="test_panel"]'
      assert_selector 'ul[id="test_panel-list"]'
      assert_selector 'li', count: 3

      # Selected tab
      assert_selector 'a[id="nav-1"][href="/home"][aria-current="page"]', text: 'Home'
      assert_selector 'a[class*="border-primary-800"][class*="text-slate-900"]', text: 'Home'

      # Unselected tabs
      assert_selector 'a[id="nav-2"][href="/profile"]', text: 'Profile'
      assert_selector 'a[id="nav-3"][href="/settings"]', text: 'Settings'
      assert_selector 'a[class*="border-transparent"][class*="text-slate-700"]', count: 2
    end

    test 'navigation with label' do
      tabs_component = Pathogen::TabsPanel.new(
        id: 'test_panel',
        label: 'Main Navigation'
      ).tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Home', href: '/home', selected: true)
        nav.with_tab(id: 'nav-2', text: 'Profile', href: '/profile')
      end
      render_inline(tabs_component)

      assert_selector 'nav[aria-label="Main Navigation"]'
    end

    test 'navigation with icons' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Home', href: '/home', selected: true) do |tab|
          tab.with_icon(icon: 'house')
        end
        nav.with_tab(id: 'nav-2', text: 'Profile', href: '/profile') do |tab|
          tab.with_icon(icon: 'user')
        end
      end
      render_inline(tabs_component)

      assert_selector 'svg[class*="size-4"]', count: 2
      assert_selector 'a[aria-label="Home"]'
      assert_selector 'a[aria-label="Profile"]'
    end

    test 'navigation with counts' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Home', href: '/home', selected: true) do |tab|
          tab.with_count(count: 3)
        end
        nav.with_tab(id: 'nav-2', text: 'Profile', href: '/profile') do |tab|
          tab.with_count(count: 5)
        end
      end
      render_inline(tabs_component)

      # Count badges
      assert_selector 'span[class*="bg-slate-300"]', text: '3'
      assert_selector 'span[class*="bg-slate-100"]', text: '5'

      # ARIA labels with counts
      assert_selector 'a[aria-label="Home, with 3 items"]'
      assert_selector 'a[aria-label="Profile, with 5 items"]'
    end

    test 'navigation with custom body' do
      tabs_component = Pathogen::TabsPanel.new(
        id: 'test_panel',
        body_arguments: {
          tag: :div,
          classes: 'flex space-x-4'
        }
      ).tap do |nav|
        nav.with_tab(
          id: 'nav-1',
          text: 'Home',
          href: '/home',
          selected: true,
          wrapper_arguments: {
            tag: :div,
            classes: 'flex-1'
          }
        )
      end
      render_inline(tabs_component)

      assert_selector 'div[id="test_panel-list"][class*="flex space-x-4"]'
      assert_selector 'div[class*="flex-1"]'
    end

    test 'navigation with single item' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Home', href: '/home', selected: true)
      end
      render_inline(tabs_component)

      assert_selector 'li', count: 1
      assert_selector 'a[aria-current="page"]', text: 'Home'
    end

    test 'navigation without items' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel')
      render_inline(tabs_component)

      assert_selector 'nav[id="test_panel"]'
      assert_selector 'ul[id="test_panel-list"]'
      assert_no_selector 'li'
    end

    test 'validates required parameters' do
      # Test that tab requires text
      assert_raises ArgumentError do
        Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
          nav.with_tab(id: 'nav-1', href: '/home')
        end
      end

      # Test that tab requires href
      assert_raises ArgumentError do
        Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
          nav.with_tab(id: 'nav-1', text: 'Home')
        end
      end

      # Test that tab requires id
      assert_raises ArgumentError do
        Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
          nav.with_tab(text: 'Home', href: '/home')
        end
      end
    end

    test 'navigation with many items' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        5.times do |i|
          nav.with_tab(
            id: "nav-#{i + 1}",
            text: "Item #{i + 1}",
            href: "/item-#{i + 1}",
            selected: i.zero?
          )
        end
      end
      render_inline(tabs_component)

      assert_selector 'li', count: 5
      assert_selector 'a[aria-current="page"]', count: 1
      assert_selector 'a[class*="border-transparent"]', count: 4
    end

    test 'navigation with long content' do
      tabs_component = Pathogen::TabsPanel.new(id: 'test_panel').tap do |nav|
        nav.with_tab(id: 'nav-1', text: 'Long Content', href: '/long', selected: true)
      end
      render_inline(tabs_component)

      assert_selector 'nav[class*="w-full"]'
      assert_selector 'ul[class*="w-full"]'
    end

    test 'generates unique id when not provided' do
      tabs_component = Pathogen::TabsPanel.new
      render_inline(tabs_component)

      assert_selector 'nav[id^="tabs-panel-"]'
      assert_selector 'ul[id^="tabs-panel-"][id$="-list"]'
    end
  end
end
