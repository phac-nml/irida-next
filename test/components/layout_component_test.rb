# frozen_string_literal: true

require 'test_helper'

class LayoutComponentTest < ViewComponent::TestCase
  test 'should render the layout with a sidebar and a body' do
    user = users(:john_doe)

    with_request_url '/-/projects' do
      render_inline LayoutComponent.new(user:) do |layout|
        layout.with_sidebar(label: I18n.t(:'general.default_sidebar.projects')) do |sidebar|
          sidebar.with_header(label: I18n.t('general.default_sidebar.title'))
          sidebar.with_section do |section|
            section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects',
                              icon: 'rectangle_stack', selected: true)
            section.with_item(label: I18n.t(:'general.default_sidebar.groups'), url: '/-/groups',
                              icon: 'squares_2x2', selected: false)
          end
        end
        layout.with_body do
          'Hello, World!'
        end
      end

      assert_link I18n.t('components.layout.main_content_link'), count: 1, href: '#main-content'

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
