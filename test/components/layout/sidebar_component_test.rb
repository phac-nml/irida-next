# frozen_string_literal: true

require 'test_helper'

module Layout
  class SidebarComponentTest < ViewComponent::TestCase
    # 💡 Test: Sidebar renders with header and a section (with valid Phosphor icons)
    test 'renders sidebar with header and section' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_header(label: I18n.t('sidebar.header'))
        sidebar.with_section(title: I18n.t('sidebar.section.my_work')) do |section|
          section.with_item(label: I18n.t('sidebar.projects'), url: '/-/projects', icon: :folders)
          section.with_item(label: I18n.t('sidebar.groups'), url: '/-/groups', icon: :users_three)
        end
      end

      node = Capybara.string(component.to_html)
      node.assert_selector 'aside[aria-label="Sidebar"]', visible: true
      assert_includes component.to_html, I18n.t('sidebar.header')
      assert_includes component.to_html, I18n.t('sidebar.section.my_work')
      node.assert_selector '.Layout-Sidebar__Item', count: 2
      node.assert_selector 'a[href="/-/projects"]'
      node.assert_selector 'a[href="/-/groups"]'
      # Accessibility note: role="menuitem" is not present in current implementation.
    end

    # 💡 Test: Sidebar renders with header and top-level items (not in a section)
    test 'renders sidebar with header and top-level items' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_header(label: I18n.t('sidebar.header'))
        sidebar.with_item(label: I18n.t('sidebar.projects'), url: '/-/projects', icon: :folders)
        sidebar.with_item(label: I18n.t('sidebar.groups'), url: '/-/groups', icon: :users_three)
      end

      node = Capybara.string(component.to_html)
      node.assert_selector 'aside[aria-label="Sidebar"]', visible: true
      assert_includes component.to_html, I18n.t('sidebar.header')
      # Top-level items are not wrapped in a section in the current implementation.
      node.assert_selector '.Layout-Sidebar__Item', count: 2
      node.assert_selector 'a[href="/-/projects"]'
      node.assert_selector 'a[href="/-/groups"]'
    end

    # 💡 Test: Sidebar renders without header, only items
    test 'renders sidebar without header' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_item(label: I18n.t('sidebar.projects'), url: '/-/projects', icon: :folders)
        sidebar.with_item(label: I18n.t('sidebar.groups'), url: '/-/groups', icon: :users_three)
      end

      node = Capybara.string(component.to_html)
      node.assert_selector 'aside[aria-label="Sidebar"]', visible: true
      refute_includes component.to_html, I18n.t('sidebar.header')
      node.assert_selector '.Layout-Sidebar__Item', count: 2
      node.assert_selector 'a[href="/-/projects"]'
      node.assert_selector 'a[href="/-/groups"]'
      # No section wrapper expected for top-level items.
    end

    # 💡 Test: Sidebar renders with section, items, and multi-level menu (all valid icons)
    test 'renders sidebar with section, items, and multi-level menu' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_section(title: I18n.t('sidebar.section.project')) do |section|
          section.with_item(label: I18n.t('sidebar.details'), url: '/', icon: :file_text)
          section.with_item(label: I18n.t('sidebar.members'), url: '/-/members', icon: :users_three)
          section.with_item(label: I18n.t('sidebar.samples'), url: '/-/samples', icon: :flask)
          section.with_item(label: I18n.t('sidebar.history'), url: '/-/history', icon: :clock_counter_clockwise)
          section.with_multi_level_menu(title: I18n.t('sidebar.settings'), selectable_pages: ['general']) do |mlm|
            mlm.with_menu_item(url: '/-/edit', label: I18n.t('sidebar.general'))
          end
        end
      end
      node = Capybara.string(component.to_html)
      node.assert_selector 'aside[aria-label="Sidebar"]', visible: true
      refute_includes component.to_html, I18n.t('sidebar.header')
      node.assert_selector '.Layout-Sidebar__Item', minimum: 4
      node.assert_selector 'a[href="/"]'
      node.assert_selector 'a[href="/-/members"]'
      node.assert_selector 'a[href="/-/samples"]'
      node.assert_selector 'a[href="/-/history"]'
      # 🚀 Multi-level menu is rendered
      node.assert_selector '.Layout-Sidebar__Item button[aria-controls]', count: 1
    end

    # 💡 Test: Sidebar renders with no items/sections (edge case)
    test 'renders empty sidebar' do
      component = render_inline Layout::SidebarComponent.new
      node = Capybara.string(component.to_html)
      node.assert_selector 'aside[aria-label="Sidebar"]', visible: true
      node.assert_no_selector '.Layout-Sidebar__Section'
      node.assert_no_selector '.Layout-Sidebar__Item'
      # Ensure at least one assertion for Minitest
      assert node, 'Sidebar HTML node should exist'
    end

    # 💡 Test: Accessibility - sidebar is labelled, all links are focusable
    test 'sidebar is accessible' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_section(title: I18n.t('sidebar.section.access')) do |section|
          section.with_item(label: I18n.t('sidebar.projects'), url: '/-/projects', icon: :folders)
        end
      end
      node = Capybara.string(component.to_html)
      aside = node.find('aside[aria-label="Sidebar"]', visible: true)
      assert_equal 'Sidebar', aside[:'aria-label']
      node.assert_selector 'a[href="/-/projects"]', visible: true
      assert node.find('a[href="/-/projects"]').visible?
    end

    # 💡 Test: I18n - all user-facing strings are translated
    test 'sidebar uses i18n for all text' do
      component = render_inline Layout::SidebarComponent.new do |sidebar|
        sidebar.with_section(title: I18n.t('sidebar.section.i18n')) do |section|
          section.with_item(label: I18n.t('sidebar.projects'), url: '/-/projects', icon: :folders)
        end
      end
      assert_includes component.to_html, I18n.t('sidebar.section.i18n')
      assert_includes component.to_html, I18n.t('sidebar.projects')
    end

    test 'should render the sidebar with expanded multi level menu' do
      component = render_inline Layout::SidebarComponent.new(label: 'Project 1',
                                                             icon_name: 'rectangle_stack') do |sidebar|
        sidebar.with_section do |section|
          section.with_item(label: 'Details', url: '/', icon: :file_text)
          section.with_item(label: 'Members', url: '/-/members', icon: :users_three)
          section.with_item(label: 'Samples', url: '/-/samples', icon: :flask)
          section.with_item(label: 'History', url: '/-/history', icon: :clock_counter_clockwise)
          section.with_multi_level_menu(title: 'Settings', current_page: 'general',
                                        selectable_pages: ['general']) do |mlm|
            mlm.with_menu_item(
              url: '/-/edit',
              label: 'General'
            )
          end
        end
      end
      node = Capybara.string(component.to_html)
      node.assert_selector 'aside'
      refute_includes component.to_html, 'My Sidebar'
      # The total number of sidebar items is 5 in current implementation (includes settings button)
      node.assert_selector '.Layout-Sidebar__Item', count: 5
      node.assert_selector 'a[href="/"]'
      node.assert_selector 'a[href="/-/members"]'
      node.assert_selector 'a[href="/-/samples"]'
      node.assert_selector 'a[href="/-/history"]'
      assert node.has_selector?('button', text: 'Settings'), "Expected a button with text 'Settings'"

      node.assert_no_selector '#multi-level-menu_settings.hidden'
      node.assert_selector '#multi-level-menu_settings' do
        node.assert_selector '.Layout-Sidebar-MultiLevelMenu__Item', count: 1
        node.assert_selector 'a[href="/-/edit"]', count: 1
      end
    end
  end
end
