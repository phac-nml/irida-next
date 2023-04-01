# frozen_string_literal: true

require 'test_helper'

class LayoutComponentTest < ViewComponent::TestCase
  test 'should render the layout with a sidebar and a body' do
    user = users(:john_doe)

    with_request_url '/-/projects' do
      render_inline Layout::LayoutComponent.new(user:) do |layout|
        layout.sidebar do |sidebar|
          sidebar.with_header(label: 'Home', url: '/', icon: 'home')
          sidebar.with_section do |section|
            section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
            section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups',
                              icon: 'cog_6_tooth')
          end
        end
        layout.body do
          'Hello, World!'
        end
      end

      assert_selector 'aside' do
        assert_text 'Home'
        assert_selector 'ul.pt-1.space-y-1' do
          assert_selector 'li.sidebar-item', count: 2
          assert_selector 'a.active[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end

      assert_selector '.content' do
        assert_text 'Hello, World!'
      end
    end
  end
end
