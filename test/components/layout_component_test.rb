# frozen_string_literal: true

require 'test_helper'

class LayoutComponentTest < ViewComponent::TestCase
  test 'renders layout with sidebar and body' do
    user = users(:john_doe)

    with_request_url '/-/projects' do
      render_inline LayoutComponent.new(user:) do |layout|
        layout.with_sidebar do |sidebar|
          sidebar.with_header(label: I18n.t('general.default_sidebar.title'))
          sidebar.with_section(title: 'Navigation') do |section|
            section.with_item(label: I18n.t(:'general.default_sidebar.projects'),
                              url: '/-/projects',
                              selected: true)
            section.with_item(label: I18n.t(:'general.default_sidebar.groups'),
                              url: '/-/groups')
          end
        end
        layout.with_body { 'Hello, World!' }
        layout.with_language_selection(user: user)
      end

      # Verify main content link for accessibility
      assert_link I18n.t('components.layout.main_content_link'),
                  count: 1,
                  href: '#main-content'

      # Verify sidebar structure
      assert_selector 'aside' do
        # Check for the presence of navigation items rather than specific text
        # This is more resilient to changes in the exact text content
        assert_selector 'nav'

        # Check for the presence of navigation items
        assert_selector 'a[href="/-/projects"]',
                        text: /#{Regexp.escape(I18n.t(:'general.default_sidebar.projects'))}/i
        assert_selector 'a[href="/-/groups"]',
                        text: /#{Regexp.escape(I18n.t(:'general.default_sidebar.groups'))}/i

        # Check for active state on current page
        assert_selector 'a[href="/-/projects"][aria-current="page"]'
      end

      # Verify main content
      assert_selector '.content', text: 'Hello, World!'

      # Verify language selection
      assert_button I18n.t('locales.en')
    end
  end

  test 'renders with collapsed sidebar when specified' do
    user = users(:john_doe)

    render_inline LayoutComponent.new(user: user) do |layout|
      layout.with_sidebar(collapsed_by_default: true) do |sidebar|
        sidebar.with_header(label: 'Collapsible Sidebar')
      end
      layout.with_body { 'Content' }
    end

    # The layout controller might be on the aside or a parent element
    assert_selector '[data-controller~="layout"]'
  end

  test 'renders with pipelines disabled' do
    user = users(:john_doe)

    render_inline LayoutComponent.new(user: user) do |layout|
      layout.with_sidebar(pipelines_enabled: false) do |sidebar|
        sidebar.with_header(label: 'No Pipelines')
      end
      layout.with_body { 'Content' }
    end

    assert_selector 'aside'
  end

  test 'renders with custom sidebar classes' do
    user = users(:john_doe)

    render_inline LayoutComponent.new(user: user) do |layout|
      layout.with_sidebar do |sidebar|
        sidebar.with_header(label: 'Custom Sidebar')
        sidebar.with_section(title: 'Section') do |section|
          section.with_item(label: 'Test', url: '/test')
        end
      end
      layout.with_body { 'Content' }
    end

    # Verify the sidebar renders with content
    assert_selector 'aside'
  end

  test 'renders with multiple sections in sidebar' do
    user = users(:john_doe)

    render_inline LayoutComponent.new(user: user) do |layout|
      layout.with_sidebar do |sidebar|
        sidebar.with_header(label: 'Multi-Section')

        sidebar.with_section(title: 'Section 1') do |section|
          section.with_item(label: 'Item 1', url: '/item1')
        end

        sidebar.with_section(title: 'Section 2') do |section|
          section.with_item(label: 'Item 2', url: '/item2')
        end
      end
      layout.with_body { 'Content' }
    end

    assert_selector 'h3', text: 'Section 1'
    assert_selector 'h3', text: 'Section 2'
    assert_selector 'a[href="/item1"]', text: 'Item 1'
    assert_selector 'a[href="/item2"]', text: 'Item 2'
  end
end
