# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for Pathogen::Tabs component
  # Validates complete tabs functionality including ARIA compliance and validation
  # rubocop:disable Metrics/ClassLength
  class TabsTest < ViewComponent::TestCase
    test 'renders with proper ARIA structure' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First', selected: true)
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # Should render with tablist role
      assert_selector '[role="tablist"]'
      assert_selector '[role="tablist"][aria-label="Test tabs"]'

      # Should render correct number of tabs and panels
      assert_selector '[role="tab"]', count: 2
      assert_selector '[role="tabpanel"]', count: 2
    end

    test 'initially selected tab has aria-selected true' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First', selected: true)
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # First tab should be selected
      assert_selector '[role="tab"][aria-selected="true"]#tab-1'
      # Second tab should not be selected
      assert_selector '[role="tab"][aria-selected="false"]#tab-2'
    end

    test 'tab-panel ARIA relationships' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # Tabs should have aria-controls (will be set by JavaScript in real implementation)
      assert_selector '[role="tab"]#tab-1'
      assert_selector '[role="tab"]#tab-2'

      # Panels should have aria-labelledby
      assert_selector '[role="tabpanel"]#panel-1[aria-labelledby="tab-1"]'
      assert_selector '[role="tabpanel"]#panel-2[aria-labelledby="tab-2"]'
    end

    test 'roving tabindex pattern' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First', selected: true)
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # Selected tab should have tabindex="0"
      assert_selector '[role="tab"]#tab-1[tabindex="0"]'
      # Unselected tab should have tabindex="-1"
      assert_selector '[role="tab"]#tab-2[tabindex="-1"]'
    end

    test 'initially selected panel visibility' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First', selected: true)
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # Both panels initially have hidden class (JS will show selected one)
      assert_selector '[role="tabpanel"]#panel-1.hidden'
      assert_selector '[role="tabpanel"]#panel-2.hidden'
    end

    test 'renders with Stimulus controller attributes' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs', default_index: 1).tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_tab(id: 'tab-2', label: 'Second', selected: true)
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      # Should have Stimulus controller
      assert_selector '[data-controller="pathogen--tabs"]'
      # Should have default index value
      assert_selector '[data-pathogen--tabs-default-index-value="1"]'
    end

    test 'tabs have correct Stimulus targets and actions' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
      end

      render_inline(tabs)

      # Tabs should have target
      assert_selector '[role="tab"][data-pathogen--tabs-target="tab"]'
      # Tabs should have actions
      assert_selector '[role="tab"][data-action*="click->pathogen--tabs#selectTab"]'
      assert_selector '[role="tab"][data-action*="keydown->pathogen--tabs#handleKeyDown"]'
    end

    test 'panels have correct Stimulus targets' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
      end

      render_inline(tabs)

      # Panels should have target
      assert_selector '[role="tabpanel"][data-pathogen--tabs-target="panel"]'
    end

    # NOTE: Validation tests for empty tabs/mismatched panels are not included
    # because these are edge cases that should be caught during development.
    # The before_render_check validation in the component handles these cases
    # in real usage.

    test 'renders with horizontal orientation by default' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
      end

      render_inline(tabs)

      assert_selector '[role="tablist"][aria-orientation="horizontal"]'
    end

    test 'renders with vertical orientation when specified' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs', orientation: :vertical).tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
      end

      render_inline(tabs)

      assert_selector '[role="tablist"][aria-orientation="vertical"]'
    end

    test 'renders tab labels' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First Tab')
        t.with_tab(id: 'tab-2', label: 'Second Tab')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
      end

      render_inline(tabs)

      assert_text 'First Tab'
      assert_text 'Second Tab'
    end

    test 'renders panel content' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Panel 1 Content' }
      end

      render_inline(tabs)

      assert_text 'Panel 1 Content'
    end

    # Validation tests
    test 'raises error when id is missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::Tabs.new(label: 'Test tabs')
      end

      assert_equal 'missing keyword: :id', error.message
    end

    test 'raises error when label is missing' do
      error = assert_raises(ArgumentError) do
        Pathogen::Tabs.new(id: 'test-tabs')
      end

      assert_equal 'missing keyword: :label', error.message
    end

    test 'raises error when no tabs are provided' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs')
        render_inline(tabs)
      end

      assert_equal 'At least one tab is required', error.message
    end

    test 'raises error when no panels are provided' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
        end
        render_inline(tabs)
      end

      assert_equal 'At least one panel is required', error.message
    end

    test 'raises error when tab and panel counts do not match' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_tab(id: 'tab-2', label: 'Second')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        end
        render_inline(tabs)
      end

      assert_equal 'Tab and panel counts must match', error.message
    end

    test 'raises error when default_index is out of bounds (negative)' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs', default_index: -1).tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        end
        render_inline(tabs)
      end

      assert_match(/default_index -1 out of bounds/, error.message)
    end

    test 'raises error when default_index is out of bounds (too large)' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs', default_index: 5).tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_tab(id: 'tab-2', label: 'Second')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
          t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
        end
        render_inline(tabs)
      end

      assert_match(/default_index 5 out of bounds \(2 tabs\)/, error.message)
    end

    test 'raises error when duplicate tab IDs are found' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_tab(id: 'tab-1', label: 'Second') # Duplicate ID
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
          t.with_panel(id: 'panel-2', tab_id: 'tab-1') { 'Content 2' }
        end
        render_inline(tabs)
      end

      assert_equal 'Duplicate tab IDs found', error.message
    end

    test 'raises error when duplicate panel IDs are found' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_tab(id: 'tab-2', label: 'Second')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
          t.with_panel(id: 'panel-1', tab_id: 'tab-2') { 'Content 2' } # Duplicate ID
        end
        render_inline(tabs)
      end

      assert_equal 'Duplicate panel IDs found', error.message
    end

    test 'raises error when panel references non-existent tab' do
      error = assert_raises(ArgumentError) do
        tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_tab(id: 'tab-2', label: 'Second')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
          t.with_panel(id: 'panel-2', tab_id: 'non-existent-tab') { 'Content 2' }
        end
        render_inline(tabs)
      end

      assert_match(/Panel panel-2 references non-existent tab non-existent-tab/, error.message)
    end

    test 'falls back to horizontal when invalid orientation is provided' do
      # Invalid orientation should raise an error in test environment
      error = assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
        Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs', orientation: :invalid).tap do |t|
          t.with_tab(id: 'tab-1', label: 'First')
          t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        end
      end

      assert_match(/Expected one of: \[:horizontal, :vertical\]/, error.message)
      assert_match(/Got: :invalid/, error.message)
    end

    # Right content slot tests
    test 'renders without right_content slot' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
      end

      render_inline(tabs)

      # Should render successfully without right_content
      assert_selector '[role="tablist"]'
    end

    test 'renders with right_content slot' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_right_content { '<button>Action</button>'.html_safe }
      end

      render_inline(tabs)

      # Should render the right content
      assert_selector 'button', text: 'Action'
    end

    test 'right_content renders alongside tabs' do
      tabs = Pathogen::Tabs.new(id: 'test-tabs', label: 'Test tabs').tap do |t|
        t.with_tab(id: 'tab-1', label: 'First')
        t.with_tab(id: 'tab-2', label: 'Second')
        t.with_panel(id: 'panel-1', tab_id: 'tab-1') { 'Content 1' }
        t.with_panel(id: 'panel-2', tab_id: 'tab-2') { 'Content 2' }
        t.with_right_content { '<span class="badge">New</span>'.html_safe }
      end

      render_inline(tabs)

      # Both tabs and right content should be present
      assert_selector '[role="tab"]', text: 'First'
      assert_selector '[role="tab"]', text: 'Second'
      assert_selector '.badge', text: 'New'
    end
  end
  # rubocop:enable Metrics/ClassLength
end
