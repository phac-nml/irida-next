# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    class TextTest < ViewComponent::TestCase
      test 'renders paragraph tag by default' do
        render_inline(Text.new) { 'Test text' }

        assert_selector 'p', text: 'Test text'
      end

      test 'renders custom tag when specified' do
        render_inline(Text.new(tag: :div)) { 'Test text' }

        assert_selector 'div', text: 'Test text'
        assert_no_selector 'p'
      end

      test 'applies base text size' do
        render_inline(Text.new) { 'Test' }

        assert_selector 'p.text-base'
      end

      test 'applies normal leading' do
        render_inline(Text.new) { 'Test' }

        assert_selector 'p.leading-normal'
      end

      test 'applies default variant color classes' do
        render_inline(Text.new) { 'Test' }

        assert_selector 'p.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(Text.new(variant: :muted)) { 'Test' }

        assert_selector 'p.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(Text.new(variant: :subdued)) { 'Test' }

        assert_selector 'p.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
        render_inline(Text.new(variant: :inverse)) { 'Test' }

        assert_selector 'p.text-white.dark\\:text-slate-900'
      end

      test 'merges custom classes' do
        render_inline(Text.new(class: 'custom-text mb-4')) { 'Test' }

        assert_selector 'p.custom-text.mb-4.text-base'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Text.new(id: 'intro', data: { test: 'value' })) { 'Test' }

        assert_selector 'p#intro[data-test="value"]'
      end

      test 'raises error for invalid variant in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Text.new(variant: :invalid)
        end
      end

      test 'supports span tag for inline text' do
        render_inline(Text.new(tag: :span)) { 'Inline text' }

        assert_selector 'span.text-base', text: 'Inline text'
      end

      test 'supports article tag for semantic markup' do
        render_inline(Text.new(tag: :article)) { 'Article content' }

        assert_selector 'article.text-base', text: 'Article content'
      end
    end
  end
end
