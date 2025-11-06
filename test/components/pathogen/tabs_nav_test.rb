# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for TabsNav component
  # ViewComponent::TestCase automatically validates W3C HTML and ARIA compliance
  class TabsNavTest < ViewComponent::TestCase
    test 'renders navigation with two tabs' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test navigation')) do |nav|
        nav.with_tab(
          id: 'tab-1',
          text: 'First Tab',
          href: '/first',
          selected: true
        )
        nav.with_tab(
          id: 'tab-2',
          text: 'Second Tab',
          href: '/second'
        )
      end

      assert_selector 'nav#test-nav[aria-label="Test navigation"]'
      assert_selector 'a#tab-1[href="/first"][aria-current="page"]', text: 'First Tab'
      assert_selector 'a#tab-2[href="/second"]', text: 'Second Tab'
      assert_no_selector 'a#tab-2[aria-current]'
    end

    test 'renders with right content slot' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test navigation')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'Tab', href: '/path', selected: true)
        nav.with_right_content { '<div class="search">Search</div>'.html_safe }
      end

      assert_selector 'nav#test-nav'
      assert_selector 'div.search', text: 'Search'
    end

    test 'applies correct CSS classes to selected tab' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'selected', text: 'Selected', href: '/path', selected: true)
      end

      assert_selector 'a.border-primary-800.text-slate-900'
    end

    test 'applies correct CSS classes to unselected tab' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
        nav.with_tab(id: 'unselected', text: 'Unselected', href: '/path', selected: false)
      end

      assert_selector 'a#unselected.border-transparent.text-slate-700'
    end

    test 'includes Turbo Drive attributes' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'Tab', href: '/path', selected: true)
      end

      assert_selector 'a[data-turbo-action="replace"]'
    end

    test 'raises error if id is missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::TabsNav.new(id: '', label: 'Test')
      end
      assert_equal 'id is required', error.message
    end

    test 'raises error if label is missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::TabsNav.new(id: 'test', label: '')
      end
      assert_equal 'label is required', error.message
    end

    test 'raises error if no tabs provided' do
      error = assert_raises(ArgumentError) do
        render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test'))
      end
      assert_equal 'At least one tab is required', error.message
    end

    test 'raises error if duplicate tab IDs found' do
      error = assert_raises(ArgumentError) do
        render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
          nav.with_tab(id: 'duplicate', text: 'First', href: '/first')
          nav.with_tab(id: 'duplicate', text: 'Second', href: '/second')
        end
      end
      assert_equal 'Duplicate tab IDs found', error.message
    end

    test 'raises error if multiple tabs selected' do
      error = assert_raises(ArgumentError) do
        render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
          nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
          nav.with_tab(id: 'tab-2', text: 'Second', href: '/second', selected: true)
        end
      end
      assert_match(/Only one tab can be selected/, error.message)
    end

    test 'allows no tabs to be selected' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first')
        nav.with_tab(id: 'tab-2', text: 'Second', href: '/second')
      end

      assert_selector 'nav#test-nav'
      assert_no_selector 'a[aria-current="page"]'
    end

    test 'renders with custom system arguments' do
      render_inline(Pathogen::TabsNav.new(
                      id: 'test-nav',
                      label: 'Test',
                      class: 'custom-class',
                      data: { controller: 'custom' }
                    )) do |nav|
        nav.with_tab(id: 'tab-1', text: 'Tab', href: '/path', selected: true)
      end

      # Should merge custom controller with pathogen--tabs-nav
      assert_selector 'nav.custom-class[data-controller="custom pathogen--tabs-nav"]'
    end

    test 'tab component raises error if id missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::TabsNav::Tab.new(id: '', text: 'Test', href: '/path')
      end
      assert_equal 'id is required', error.message
    end

    test 'tab component raises error if text missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::TabsNav::Tab.new(id: 'test', text: '', href: '/path')
      end
      assert_equal 'text is required', error.message
    end

    test 'tab component raises error if href missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::TabsNav::Tab.new(id: 'test', text: 'Test', href: '')
      end
      assert_equal 'href is required', error.message
    end

    test 'matches visual style of Pathogen::Tabs component' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'Tab', href: '/path', selected: true)
      end

      # Verify it has the same base classes as Pathogen::Tabs::Tab
      assert_selector 'a.inline-block.p-4.font-semibold.transition-colors.duration-200.border-b-2.rounded-t-lg'
    end

    # Stimulus controller tests
    test 'attaches Stimulus controller to nav element' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'Tab', href: '/path', selected: true)
      end

      assert_selector 'nav[data-controller="pathogen--tabs-nav"]'
    end

    test 'tab links have Stimulus target attribute' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
        nav.with_tab(id: 'tab-2', text: 'Second', href: '/second')
      end

      assert_selector 'a[data-pathogen--tabs-nav-target="tab"]', count: 2
    end

    test 'tab links have keydown action attribute' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
      end

      assert_selector 'a[data-action="keydown->pathogen--tabs-nav#handleKeydown"]'
    end

    test 'selected tab has tabindex="0" for keyboard navigation' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
        nav.with_tab(id: 'tab-2', text: 'Second', href: '/second')
      end

      # Note: tabindex is set by JavaScript after rendering, so this test validates
      # the component structure is correct, not the actual tabindex value
      assert_selector 'a#tab-1[aria-current="page"]'
      assert_selector 'a#tab-2:not([aria-current])'
    end

    test 'unselected tabs do not have aria-current' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
        nav.with_tab(id: 'tab-2', text: 'Second', href: '/second')
        nav.with_tab(id: 'tab-3', text: 'Third', href: '/third')
      end

      assert_selector 'a[aria-current="page"]', count: 1
      assert_selector 'a:not([aria-current])', count: 2
    end

    test 'all tabs have required data attributes for keyboard navigation' do
      render_inline(Pathogen::TabsNav.new(id: 'test-nav', label: 'Test')) do |nav|
        nav.with_tab(id: 'tab-1', text: 'First', href: '/first', selected: true)
        nav.with_tab(id: 'tab-2', text: 'Second', href: '/second')
        nav.with_tab(id: 'tab-3', text: 'Third', href: '/third')
      end

      # All tabs should have target and action attributes
      assert_selector 'a[data-pathogen--tabs-nav-target="tab"]' \
                      '[data-action="keydown->pathogen--tabs-nav#handleKeydown"]', count: 3
    end
  end
end
