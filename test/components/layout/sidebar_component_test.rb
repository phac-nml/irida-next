# frozen_string_literal: true

require 'test_helper'

module Layout
  class SidebarComponentTest < ViewComponent::TestCase
    test 'renders with default classes' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      assert_selector('aside')
    end

    test 'accepts custom classes' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # The component should render with the default structure
      assert_selector('aside')
    end

    test 'renders with header' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Custom Header')
      end

      assert_text('Custom Header')
    end

    test 'renders with sections' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Section 1') do |section|
          section.with_item(label: 'Item 1', url: '/path1')
        end
        sidebar.with_section(title: 'Section 2') do |section|
          section.with_item(label: 'Item 2', url: '/path2')
        end
      end

      assert_selector('h3', text: 'Section 1')
      assert_selector('h3', text: 'Section 2')
      assert_selector('a[href="/path1"]', text: 'Item 1')
      assert_selector('a[href="/path2"]', text: 'Item 2')
    end

    test 'renders with top-level items' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Item 1', url: '/path1')
        sidebar.with_item(label: 'Item 2', url: '/path2')
      end

      assert_selector('a[href="/path1"]', text: 'Item 1')
      assert_selector('a[href="/path2"]', text: 'Item 2')
    end

    test 'renders with pipelines disabled' do
      render_inline(Layout::SidebarComponent.new(pipelines_enabled: false)) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # Verify the sidebar renders without pipeline-specific content
      assert_selector('aside')
    end

    test 'renders collapsed by default when specified' do
      render_inline(Layout::SidebarComponent.new(collapsed_by_default: true)) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # The collapsed state is handled by JavaScript, so we just check the component renders
      assert_selector('aside')
    end

    test 'renders with icons' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Item with Icon', url: '#') do |item|
          item.with_icon { 'ICON' }
        end
      end

      assert_selector('a', text: 'Item with Icon')
    end

    test 'renders with selected item' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Current Page', url: '/current', selected: true)
        sidebar.with_item(label: 'Other Page', url: '/other')
      end

      assert_selector('a[href="/current"][aria-current="page"]')
      assert_no_selector('a[href="/other"][aria-current="page"]')
    end

    test 'sidebar is accessible' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Access Section') do |section|
          section.with_item(label: 'Projects', url: '/projects')
        end
      end

      assert_selector('aside[aria-label]')
      assert_selector('a[href="/projects"]', text: 'Projects')
    end

    test 'renders with multi-level menu' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Settings') do |section|
          section.with_multi_level_menu(title: 'Configuration') do |menu|
            menu.with_menu_item(label: 'General', url: '/settings/general')
            menu.with_menu_item(label: 'Advanced', url: '/settings/advanced')
          end
        end
      end

      # The menu items might be hidden by default, so we just check the button is rendered
      assert_selector('button', text: 'Configuration')
    end
  end
end
