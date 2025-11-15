# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    # Test suite for Code component
    class CodeTest < ViewComponent::TestCase
      test 'renders code tag' do
        render_inline(Code.new) { 'variable_name' }

        assert_selector 'code', text: 'variable_name'
      end

      test 'applies monospace font' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.font-mono'
      end

      test 'applies small text size' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.text-sm'
      end

      test 'applies background color' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.bg-slate-100.dark\\:bg-slate-800'
      end

      test 'applies text color' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.text-slate-800.dark\\:text-slate-100'
      end

      test 'applies padding' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.px-2.py-0\\.5'
      end

      test 'applies rounded corners' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.rounded-md'
      end

      test 'applies border' do
        render_inline(Code.new) { 'Test' }

        assert_selector 'code.border.border-slate-200.dark\\:border-slate-700'
      end

      test 'merges custom classes' do
        render_inline(Code.new(class: 'custom-code')) { 'Test' }

        assert_selector 'code.custom-code.font-mono'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Code.new(id: 'example', data: { lang: 'ruby' })) { 'Test' }

        assert_selector 'code#example[data-lang="ruby"]'
      end

      test 'preserves code content without modification' do
        render_inline(Code.new) { '<script>alert("test")</script>' }

        assert_selector 'code', text: '<script>alert("test")</script>'
      end

      test 'renders inline within text' do
        render_inline(Code.new) { 'code_snippet' }

        # Code uses inline-flex for better alignment
        assert_selector 'code.inline-flex'
      end
    end
  end
end
