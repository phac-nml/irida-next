# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class TabsNav
    class PanelTest < ViewComponent::TestCase
      test 'raises error when id is missing' do
        assert_raises(ArgumentError, 'id is required') do
          render_inline(Pathogen::TabsNav::Panel.new(tab_id: 'test-tab'))
        end
      end

      test 'raises error when tab_id is missing' do
        assert_raises(ArgumentError, 'tab_id is required') do
          render_inline(Pathogen::TabsNav::Panel.new(id: 'test-panel'))
        end
      end

      test 'renders selected panel with content' do
        render_inline(Pathogen::TabsNav::Panel.new(
          id: 'test-panel',
          tab_id: 'test-tab',
          selected: true
        )) do
          'Panel content here'
        end

        assert_selector 'div#test-panel[role="tabpanel"]'
        assert_selector 'div[aria-labelledby="test-tab"]'
        assert_selector 'div[aria-hidden="false"]'
        assert_selector 'div[tabindex="0"]'
        assert_text 'Panel content here'
        refute_selector '.hidden'
      end

      test 'renders unselected panel with spinner and hidden class' do
        render_inline(Pathogen::TabsNav::Panel.new(
          id: 'test-panel',
          tab_id: 'test-tab',
          selected: false
        )) do
          'Panel content that should not render'
        end

        assert_selector 'div#test-panel[role="tabpanel"]'
        assert_selector 'div[aria-labelledby="test-tab"]'
        assert_selector 'div[aria-hidden="true"]'
        assert_selector 'div[tabindex="0"]'
        assert_selector 'div.hidden'
        assert_text I18n.t('pathogen.tabs_nav.panel.loading')
        refute_text 'Panel content that should not render'
      end

      test 'defaults to unselected when selected parameter is omitted' do
        render_inline(Pathogen::TabsNav::Panel.new(
          id: 'test-panel',
          tab_id: 'test-tab'
        )) do
          'Panel content'
        end

        assert_selector 'div[aria-hidden="true"]'
        assert_selector 'div.hidden'
        assert_text I18n.t('pathogen.tabs_nav.panel.loading')
      end

      test 'accepts additional system arguments' do
        render_inline(Pathogen::TabsNav::Panel.new(
          id: 'test-panel',
          tab_id: 'test-tab',
          selected: true,
          class: 'custom-class',
          data: { controller: 'custom' }
        )) do
          'Content'
        end

        assert_selector 'div.custom-class'
        assert_selector 'div[data-controller="custom"]'
      end

      test 'renders complex content in selected panel' do
        render_inline(Pathogen::TabsNav::Panel.new(
          id: 'complex-panel',
          tab_id: 'complex-tab',
          selected: true
        )) do
          '<div class="content"><h2>Title</h2><p>Paragraph</p></div>'.html_safe
        end

        assert_selector 'div.content'
        assert_selector 'h2', text: 'Title'
        assert_selector 'p', text: 'Paragraph'
      end
    end
  end
end
