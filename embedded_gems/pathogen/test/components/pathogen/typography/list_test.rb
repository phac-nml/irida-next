# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    # Test suite for List component
    class ListTest < ViewComponent::TestCase
      test 'renders unordered list by default' do
        render_inline(List.new) do |list|
          list.with_item { 'Item 1' }
          list.with_item { 'Item 2' }
        end

        assert_selector 'ul'
        assert_selector 'li', count: 2
      end

      test 'renders ordered list when specified' do
        render_inline(List.new(ordered: true)) do |list|
          list.with_item { 'First' }
          list.with_item { 'Second' }
        end

        assert_selector 'ol'
        assert_no_selector 'ul'
      end

      test 'renders all list items' do
        render_inline(List.new) do |list|
          list.with_item { 'Apple' }
          list.with_item { 'Banana' }
          list.with_item { 'Cherry' }
        end

        assert_selector 'li', text: 'Apple'
        assert_selector 'li', text: 'Banana'
        assert_selector 'li', text: 'Cherry'
      end

      test 'applies typography and layout classes' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ul.text-base.leading-normal.list-disc.pl-6.space-y-2'

        render_inline(List.new(ordered: true)) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ol.list-decimal'
      end

      test 'applies variant color classes' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ul.text-slate-900.dark\\:text-white'

        render_inline(List.new(variant: :muted)) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ul.text-slate-500.dark\\:text-slate-400'

        render_inline(List.new(variant: :subdued)) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ul.text-slate-700.dark\\:text-slate-300'

        render_inline(List.new(variant: :inverse)) do |list|
          list.with_item { 'Test' }
        end
        assert_selector 'ul.text-white.dark\\:text-slate-900'
      end

      test 'merges custom classes' do
        render_inline(List.new(class: 'my-list')) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.my-list.list-disc'
      end

      test 'accepts additional HTML attributes' do
        render_inline(List.new(id: 'features', role: 'list')) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul#features[role="list"]'
      end

      test 'raises error for invalid variant in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          List.new(variant: :invalid)
        end
      end

      test 'handles edge cases correctly' do
        render_inline(List.new)
        assert_selector 'ul'
        assert_no_selector 'li'

        render_inline(List.new) do |list|
          list.with_item { 'Item with & ampersand' }
        end
        assert_selector 'li', text: 'Item with & ampersand'
      end
    end
  end
end
