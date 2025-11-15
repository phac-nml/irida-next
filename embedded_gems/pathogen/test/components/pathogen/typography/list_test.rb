# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
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

      test 'applies base text size' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.text-base'
      end

      test 'applies normal leading' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.leading-normal'
      end

      test 'applies list disc style to unordered lists' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.list-disc'
      end

      test 'applies list decimal style to ordered lists' do
        render_inline(List.new(ordered: true)) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ol.list-decimal'
      end

      test 'applies left padding for list markers' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.pl-6'
      end

      test 'applies spacing between items' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.space-y-2'
      end

      test 'applies default variant color classes' do
        render_inline(List.new) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(List.new(variant: :muted)) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(List.new(variant: :subdued)) do |list|
          list.with_item { 'Test' }
        end

        assert_selector 'ul.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
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

      test 'handles empty list gracefully' do
        render_inline(List.new)

        assert_selector 'ul'
        assert_no_selector 'li'
      end

      test 'preserves HTML entities in list items' do
        render_inline(List.new) do |list|
          list.with_item { 'Item with & ampersand' }
        end

        assert_selector 'li', text: 'Item with & ampersand'
      end

      test 'ordered list uses correct numbering' do
        render_inline(List.new(ordered: true)) do |list|
          list.with_item { 'First' }
          list.with_item { 'Second' }
          list.with_item { 'Third' }
        end

        assert_selector 'ol.list-decimal'
        assert_selector 'li', count: 3
      end
    end
  end
end
