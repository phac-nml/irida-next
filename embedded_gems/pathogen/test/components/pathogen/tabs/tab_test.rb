# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class Tabs
    class TabTest < ViewComponent::TestCase
      test 'renders with role tab' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[role="tab"]'
        assert_selector 'button[role="tab"]'
      end

      test 'renders with correct id' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[role="tab"]#tab-1'
      end

      test 'renders with label text' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_text 'First Tab'
      end

      test 'renders as button element' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector 'button[type="button"]'
      end

      test 'selected state has aria-selected true' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: true
        ))

        assert_selector '[role="tab"][aria-selected="true"]'
      end

      test 'unselected state has aria-selected false' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: false
        ))

        assert_selector '[role="tab"][aria-selected="false"]'
      end

      test 'selected tab has tabindex 0' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: true
        ))

        assert_selector '[role="tab"][tabindex="0"]'
      end

      test 'unselected tab has tabindex -1' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: false
        ))

        assert_selector '[role="tab"][tabindex="-1"]'
      end

      test 'has Stimulus target attribute' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[data-pathogen--tabs-target="tab"]'
      end

      test 'has click action for selectTab' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[data-action*="click->pathogen--tabs#selectTab"]'
      end

      test 'has keydown action for handleKeyDown' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[data-action*="keydown->pathogen--tabs#handleKeyDown"]'
      end

      test 'selected tab has selected CSS classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: true
        ))

        # Check for selected classes
        assert_selector '.border-primary-800'
        assert_selector '.text-slate-900'
      end

      test 'unselected tab has unselected CSS classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          selected: false
        ))

        # Check for unselected classes
        assert_selector '.border-transparent'
        assert_selector '.text-slate-700'
      end

      test 'tab has base CSS classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        # Check for base classes
        assert_selector '.inline-block'
        assert_selector '.p-4'
        assert_selector '.rounded-t-lg'
        assert_selector '.font-semibold'
        assert_selector '.border-b-2'
      end

      test 'tab has focus ring classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '.focus\\:outline-none'
        assert_selector '.focus\\:ring-2'
        assert_selector '.focus\\:ring-primary-500'
      end

      test 'tab has transition classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '.transition-colors'
        assert_selector '.duration-200'
      end

      test 'requires id parameter' do
        assert_raises(ArgumentError) do
          Pathogen::Tabs::Tab.new(label: 'First Tab')
        end
      end

      test 'requires label parameter' do
        assert_raises(ArgumentError) do
          Pathogen::Tabs::Tab.new(id: 'tab-1')
        end
      end

      test 'accepts custom CSS classes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          class: 'custom-class'
        ))

        assert_selector '.custom-class'
      end

      test 'accepts custom data attributes' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab',
          'data-test': 'my-tab'
        ))

        assert_selector '[data-test="my-tab"]'
      end

      test 'defaults to unselected when selected not specified' do
        render_inline(Pathogen::Tabs::Tab.new(
          id: 'tab-1',
          label: 'First Tab'
        ))

        assert_selector '[aria-selected="false"]'
        assert_selector '[tabindex="-1"]'
      end
    end
  end
end
