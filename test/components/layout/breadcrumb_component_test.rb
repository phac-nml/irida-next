# frozen_string_literal: true

require 'view_component_test_case'

module Layout
  class BreadcrumbComponentTest < ViewComponentTestCase
    def setup
      @links = [
        { name: 'Home', path: '/' },
        { name: 'Projects', path: '/projects' },
        { name: 'My Project', path: '/projects/my-project' }
      ]
    end

    test 'renders nothing when links are empty' do
      render_inline(Layout::BreadcrumbComponent.new(links: []))
      assert_no_selector '*'
    end

    test 'renders a single item as current page when only one link is provided' do
      links = [{ name: 'Home', path: '/' }]
      render_inline(Layout::BreadcrumbComponent.new(links:))

      assert_selector "nav[aria-label=\"#{I18n.t(:'components.breadcrumb.navigation_aria_label')}\"]"
      assert_selector 'li[data-breadcrumb-target="crumb"]', count: 1
      assert_selector 'span[aria-current="page"]', text: 'Home'
      assert_no_selector 'a', text: 'Home'
    end

    test 'renders the correct structure for multiple links' do
      render_inline(Layout::BreadcrumbComponent.new(links: @links))

      assert_selector 'nav[data-controller="breadcrumb"]'
      assert_selector 'li[data-breadcrumb-target="crumb"]', count: 3
    end

    test 'renders links correctly with the last item as the current page' do
      render_inline(Layout::BreadcrumbComponent.new(links: @links))

      # Check for linked items - note the double slashes due to root_path + path concatenation
      assert_selector "a[href='//']", text: 'Home'
      assert_selector "a[href='//projects']", text: 'Projects'

      # The last item should be a span, not a link
      assert_no_selector "a[href='//projects/my-project']"
      assert_selector 'span[aria-current="page"]', text: 'My Project'
    end

    test 'renders dropdown menu with all but the last link' do
      render_inline(Layout::BreadcrumbComponent.new(links: @links))

      assert_selector 'li[data-breadcrumb-target="dropdownMenu"]', visible: :all do
        assert_selector '[role="menuitem"]', count: 2, visible: :all
        assert_selector '[role="menuitem"]', text: 'Home', visible: :all
        assert_selector '[role="menuitem"]', text: 'Projects', visible: :all
      end
    end

    test 'validates links structure' do
      assert_raises ArgumentError, 'links must be an array' do
        Layout::BreadcrumbComponent.new(links: 'not an array')
      end

      assert_raises ArgumentError, 'All links must be hashes with :name and :path keys' do
        Layout::BreadcrumbComponent.new(links: [{ name: 'Missing Path' }])
      end

      assert_raises ArgumentError, 'All links must be hashes with :name and :path keys' do
        Layout::BreadcrumbComponent.new(links: [{ path: 'missing/name' }])
      end

      assert_raises ArgumentError, 'All links must be hashes with :name and :path keys' do
        Layout::BreadcrumbComponent.new(links: ['a string'])
      end
    end
  end
end
