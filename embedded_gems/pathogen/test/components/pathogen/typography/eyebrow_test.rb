# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    class EyebrowTest < ViewComponent::TestCase
      test 'renders paragraph tag by default with uppercase class' do
        render_inline(Eyebrow.new) { 'Category' }

        assert_selector 'p.uppercase'
        # Note: CSS transforms don't apply in test environment
        assert_selector 'p', text: 'Category'
      end

      test 'renders custom tag when specified' do
        render_inline(Eyebrow.new(tag: :span)) { 'Label' }

        assert_selector 'span.uppercase', text: 'Label'
        assert_no_selector 'p'
      end

      test 'applies extra small text size' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.text-xs'
      end

      test 'applies uppercase transformation' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.uppercase'
      end

      test 'applies wider letter spacing' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.tracking-wider'
      end

      test 'applies font semibold weight' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.font-semibold'
      end

      test 'applies body leading and font semibold' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.leading-normal.font-semibold'
      end

      test 'applies default variant color classes' do
        render_inline(Eyebrow.new) { 'Test' }

        assert_selector 'p.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(Eyebrow.new(variant: :muted)) { 'Test' }

        assert_selector 'p.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(Eyebrow.new(variant: :subdued)) { 'Test' }

        assert_selector 'p.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
        render_inline(Eyebrow.new(variant: :inverse)) { 'Test' }

        assert_selector 'p.text-white.dark\\:text-slate-900'
      end

      test 'merges custom classes' do
        render_inline(Eyebrow.new(class: 'mb-2')) { 'Test' }

        assert_selector 'p.mb-2.text-xs.uppercase'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Eyebrow.new(id: 'category', role: 'heading')) { 'Test' }

        assert_selector 'p#category[role="heading"]'
      end

      test 'falls back to default variant for invalid variant' do
        render_inline(Eyebrow.new(variant: :invalid)) { 'Test' }

        assert_selector 'p.text-slate-900.dark\\:text-white'
      end

      test 'applies uppercase CSS class' do
        render_inline(Eyebrow.new) { 'featured article' }

        assert_selector 'p.uppercase'
        # CSS uppercase transform doesn't apply in test environment, but class is present
        assert_selector 'p', text: 'featured article'
      end
    end
  end
end
