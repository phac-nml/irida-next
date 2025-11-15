# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    class SupportingTest < ViewComponent::TestCase
      test 'renders paragraph tag by default' do
        render_inline(Supporting.new) { 'Supporting text' }

        assert_selector 'p', text: 'Supporting text'
      end

      test 'renders custom tag when specified' do
        render_inline(Supporting.new(tag: :span)) { 'Supporting text' }

        assert_selector 'span', text: 'Supporting text'
        assert_no_selector 'p'
      end

      test 'applies small text size' do
        render_inline(Supporting.new) { 'Test' }

        assert_selector 'p.text-sm'
      end

      test 'applies normal leading' do
        render_inline(Supporting.new) { 'Test' }

        assert_selector 'p.leading-normal'
      end

      test 'applies default variant color classes' do
        render_inline(Supporting.new) { 'Test' }

        assert_selector 'p.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(Supporting.new(variant: :muted)) { 'Test' }

        assert_selector 'p.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(Supporting.new(variant: :subdued)) { 'Test' }

        assert_selector 'p.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
        render_inline(Supporting.new(variant: :inverse)) { 'Test' }

        assert_selector 'p.text-white.dark\\:text-slate-900'
      end

      test 'merges custom classes' do
        render_inline(Supporting.new(class: 'mt-1')) { 'Test' }

        assert_selector 'p.mt-1.text-sm'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Supporting.new(id: 'help-text', role: 'note')) { 'Test' }

        assert_selector 'p#help-text[role="note"]'
      end

      test 'raises error for invalid variant in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Supporting.new(variant: :invalid)
        end
      end

      test 'supports label tag for form labels' do
        render_inline(Supporting.new(tag: :label, for: 'email')) { 'Email address' }

        assert_selector 'label[for="email"].text-sm', text: 'Email address'
      end

      test 'supports div tag for captions' do
        render_inline(Supporting.new(tag: :div)) { 'Image caption' }

        assert_selector 'div.text-sm', text: 'Image caption'
      end
    end
  end
end
