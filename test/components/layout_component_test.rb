# frozen_string_literal: true

require 'test_helper'

class LayoutComponentTest < ViewComponent::TestCase
  test 'should render the layout with a sidebar and a body' do
    user = users(:john_doe)

    with_request_url '/-/projects' do
      render_inline LayoutComponent.new(user:) do |layout|
        layout.sidebar(label: I18n.t(:'general.default_sidebar.projects'), icon_name: 'folder') do |sidebar|
          sidebar.with_header(label: I18n.t('general.default_sidebar.title'), url: '/', icon: 'home')
          sidebar.with_section do |section|
            section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects',
                              icon: 'rectangle_stack')
            section.with_item(label: I18n.t(:'general.default_sidebar.groups'), url: '/-/groups',
                              icon: 'squares_2x2')
          end
        end
        layout.body do
          'Hello, World!'
        end
      end

      assert_selector 'aside' do
        assert_text I18n.t('general.default_sidebar.title')
        assert_selector '.Layout-Sidebar__Section' do
          assert_selector '.Layout-Sidebar__Item', count: 2
          assert_selector 'a.Layout-Sidebar__Item--selected[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end

      assert_selector '.content' do
        assert_text 'Hello, World!'
      end
    end
  end
end
