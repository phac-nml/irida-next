# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    class ListTest < ViewComponent::TestCase
      test 'renders unordered list by default' do
        render_inline(List.new(items: ['Item 1', 'Item 2']))

        assert_selector 'ul'
        assert_selector 'li', count: 2
      end

      test 'renders ordered list when specified' do
        render_inline(List.new(items: ['First', 'Second'], ordered: true))

        assert_selector 'ol'
        assert_no_selector 'ul'
      end

      test 'renders all list items' do
        items = ['Apple', 'Banana', 'Cherry']
        render_inline(List.new(items: items))

        items.each do |item|
          assert_selector 'li', text: item
        end
      end

      test 'applies base text size' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.text-base'
      end

      test 'applies normal leading' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.leading-normal'
      end

      test 'applies list disc style to unordered lists' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.list-disc'
      end

      test 'applies list decimal style to ordered lists' do
        render_inline(List.new(items: ['Test'], ordered: true))

        assert_selector 'ol.list-decimal'
      end

      test 'applies left padding for list markers' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.pl-6'
      end

      test 'applies spacing between items' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.space-y-2'
      end

      test 'applies default variant color classes' do
        render_inline(List.new(items: ['Test']))

        assert_selector 'ul.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(List.new(items: ['Test'], variant: :muted))

        assert_selector 'ul.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(List.new(items: ['Test'], variant: :subdued))

        assert_selector 'ul.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
        render_inline(List.new(items: ['Test'], variant: :inverse))

        assert_selector 'ul.text-white.dark\\:text-slate-900'
      end

      test 'merges custom classes' do
        render_inline(List.new(items: ['Test'], class: 'my-list'))

        assert_selector 'ul.my-list.list-disc'
      end

      test 'accepts additional HTML attributes' do
        render_inline(List.new(items: ['Test'], id: 'features', role: 'list'))

        assert_selector 'ul#features[role="list"]'
      end

      test 'falls back to default variant for invalid variant' do
        render_inline(List.new(items: ['Test'], variant: :invalid))

        assert_selector 'ul.text-slate-900.dark\\:text-white'
      end

      test 'handles empty items array gracefully' do
        render_inline(List.new(items: []))

        assert_selector 'ul'
        assert_no_selector 'li'
      end

      test 'handles nil items gracefully' do
        render_inline(List.new(items: nil))

        assert_selector 'ul'
        assert_no_selector 'li'
      end

      test 'preserves HTML entities in list items' do
        render_inline(List.new(items: ['Item with & ampersand']))

        assert_selector 'li', text: 'Item with & ampersand'
      end

      test 'ordered list uses correct numbering' do
        render_inline(List.new(items: ['First', 'Second', 'Third'], ordered: true))

        assert_selector 'ol.list-decimal'
        assert_selector 'li', count: 3
      end
    end
  end
end
