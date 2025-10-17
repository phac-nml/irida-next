# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class Tabs
    # Test suite for Pathogen::Tabs::TabPanel component
    # Validates ARIA attributes, keyboard accessibility, and rendering behavior
    # rubocop:disable Metrics/ClassLength
    class TabPanelTest < ViewComponent::TestCase
      test 'renders with role tabpanel' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[role="tabpanel"]'
        assert_selector 'div[role="tabpanel"]'
      end

      test 'renders with correct id' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[role="tabpanel"]#panel-1'
      end

      test 'has aria-labelledby referencing tab' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[role="tabpanel"][aria-labelledby="tab-1"]'
      end

      test 'initially has aria-hidden true' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[role="tabpanel"][aria-hidden="true"]'
      end

      test 'has tabindex 0 for keyboard focus' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[role="tabpanel"][tabindex="0"]'
      end

      test 'has Stimulus target attribute' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '[data-pathogen--tabs-target="panel"]'
      end

      test 'initially has hidden CSS class' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content'
        end

        assert_selector '.hidden'
      end

      test 'renders panel content' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          'Panel content goes here'
        end

        assert_text 'Panel content goes here'
      end

      test 'renders complex HTML content' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          '<div><h2>Title</h2><p>Paragraph</p></div>'.html_safe
        end

        assert_selector 'h2', text: 'Title'
        assert_selector 'p', text: 'Paragraph'
      end

      test 'requires id parameter' do
        assert_raises(ArgumentError) do
          Pathogen::Tabs::TabPanel.new(tab_id: 'tab-1')
        end
      end

      test 'requires tab_id parameter' do
        assert_raises(ArgumentError) do
          Pathogen::Tabs::TabPanel.new(id: 'panel-1')
        end
      end

      test 'accepts custom CSS classes' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1',
                        class: 'custom-panel-class'
                      )) do
          'Panel content'
        end

        assert_selector '.custom-panel-class'
        # Should still have hidden class
        assert_selector '.hidden'
      end

      test 'accepts custom data attributes' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1',
                        'data-test': 'my-panel'
                      )) do
          'Panel content'
        end

        assert_selector '[data-test="my-panel"]'
      end

      test 'panel can contain Turbo Frame' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      )) do
          '<turbo-frame id="frame-1" src="/path/to/content">Loading...</turbo-frame>'.html_safe
        end

        assert_selector 'turbo-frame#frame-1'
        assert_text 'Loading...'
      end

      test 'panel can be empty' do
        render_inline(Pathogen::Tabs::TabPanel.new(
                        id: 'panel-1',
                        tab_id: 'tab-1'
                      ))

        # Should render but with no content
        assert_selector '[role="tabpanel"]#panel-1'
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
