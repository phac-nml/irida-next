# frozen_string_literal: true

require 'test_helper'

module Layout
  class SidebarComponentTest < ViewComponent::TestCase
    test 'should render the sidebar with a header and a section' do
      render_inline Layout::SidebarComponent.new do |sidebar|
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
      render_inline Layout::SidebarComponent.new do |sidebar|
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
      render_inline Layout::SidebarComponent.new do |sidebar|
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
  end
end
