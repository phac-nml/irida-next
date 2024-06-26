# frozen_string_literal: true

require 'test_helper'

module Layout
  class SidebarComponentTest < ViewComponent::TestCase
    test 'should render the sidebar with a header and a section' do
      render_inline Layout::SidebarComponent.new(label: I18n.t(:'general.default_sidebar.projects'),
                                                 icon_name: 'folder') do |sidebar|
        sidebar.with_header(label: 'My Sidebar', url: '/', icon: 'home')
        sidebar.with_section(title: 'My Work') do |section|
          section.with_item(label: 'Projects', url: '/-/projects', icon: 'rectangle_stack')
          section.with_item(label: 'Groups', url: '/-/groups', icon: 'squares_2x2')
        end
      end

      assert_selector 'aside' do
        assert_text 'My Sidebar'
        assert_text 'My Work'
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 2
          assert_selector 'a[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end
    end

    test 'should render the sidebar with a header and items' do
      render_inline Layout::SidebarComponent.new(label: I18n.t(:'general.default_sidebar.projects'),
                                                 icon_name: 'folder') do |sidebar|
        sidebar.with_header(label: 'My Sidebar', url: '/', icon: 'home')
        sidebar.with_item(label: 'Projects', url: '/-/projects', icon: 'rectangle_stack')
        sidebar.with_item(label: 'Groups', url: '/-/groups', icon: 'squares_2x2')
      end

      assert_selector 'aside' do
        assert_text 'My Sidebar'
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 2
          assert_selector 'a[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end
    end

    test 'sidebar should render without a header' do
      render_inline Layout::SidebarComponent.new(label: I18n.t(:'general.default_sidebar.projects'),
                                                 icon_name: 'folder') do |sidebar|
        sidebar.with_item(label: 'Projects', url: '/-/projects', icon: 'rectangle_stack')
        sidebar.with_item(label: 'Groups', url: '/-/groups', icon: 'squares_2x2')
      end

      assert_selector 'aside' do
        assert_no_text 'My Sidebar'
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 2
          assert_selector 'a[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end
    end

    test 'should render the sidebar with no header, items, and multi level menu with items' do
      render_inline Layout::SidebarComponent.new(label: 'Project 1',
                                                 icon_name: 'rectangle_stack') do |sidebar|
        sidebar.with_section do |section|
          section.with_item(label: 'Details', url: '/', icon: 'clipboard_document')
          section.with_item(label: 'Members', url: '/-/members', icon: 'users')
          section.with_item(label: 'Samples', url: '/-/samples', icon: 'beaker')
          section.with_item(label: 'History', url: '/-/history', icon: 'list_bullet')
          section.with_multi_level_menu(title: 'Settings', selectable_pages: ['general']) do |mlm|
            mlm.with_menu_item(
              url: '/-/edit',
              label: 'General'
            )
          end
        end
      end
      assert_selector 'aside' do
        assert_no_text 'My Sidebar'
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 4
          assert_selector 'a[href="/"]'
          assert_selector 'a[href="/-/members"]'
          assert_selector 'a[href="/-/samples"]'
          assert_selector 'a[href="/-/history"]'
          assert_button text: 'Settings'

          assert_selector '#multi-level-menu_settings.hidden' do
            assert_selector '.Layout-Sidebar-MultiLevelMenu__Item', count: 1
            assert_selector 'a[href="/-/edit"]', count: 1
          end
        end
      end
    end

    test 'should render the sidebar with expanded multi level menu' do
      render_inline Layout::SidebarComponent.new(label: 'Project 1',
                                                 icon_name: 'rectangle_stack') do |sidebar|
        sidebar.with_section do |section|
          section.with_item(label: 'Details', url: '/', icon: 'clipboard_document')
          section.with_item(label: 'Members', url: '/-/members', icon: 'users')
          section.with_item(label: 'Samples', url: '/-/samples', icon: 'beaker')
          section.with_item(label: 'History', url: '/-/history', icon: 'list_bullet')
          section.with_multi_level_menu(title: 'Settings', current_page: 'general',
                                        selectable_pages: ['general']) do |mlm|
            mlm.with_menu_item(
              url: '/-/edit',
              label: 'General'
            )
          end
        end
      end
      assert_selector 'aside' do
        assert_no_text 'My Sidebar'
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 4
          assert_selector 'a[href="/"]'
          assert_selector 'a[href="/-/members"]'
          assert_selector 'a[href="/-/samples"]'
          assert_selector 'a[href="/-/history"]'
          assert_button text: 'Settings'

          assert_no_selector '#multi-level-menu_settings.hidden'
          assert_selector '#multi-level-menu_settings' do
            assert_selector '.Layout-Sidebar-MultiLevelMenu__Item', count: 1
            assert_selector 'a[href="/-/edit"]', count: 1
          end
        end
      end
    end
  end
end
