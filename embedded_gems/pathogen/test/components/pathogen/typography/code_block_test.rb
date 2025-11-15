# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    class CodeBlockTest < ViewComponent::TestCase
      test 'renders pre and code tags' do
        render_inline(CodeBlock.new) { 'code content' }

        assert_selector 'pre > code', text: 'code content'
      end

      test 'applies monospace font to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.font-mono'
      end

      test 'applies small text size to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.text-sm'
      end

      test 'applies dark background to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.bg-slate-900.dark\\:bg-slate-950'
      end

      test 'applies light text color to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.text-slate-100'
      end

      test 'applies padding to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.p-4'
      end

      test 'applies rounded corners to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.rounded-lg'
      end

      test 'applies overflow handling to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.overflow-x-auto'
      end

      test 'applies leading relaxed to pre' do
        render_inline(CodeBlock.new) { 'Test' }

        assert_selector 'pre.leading-relaxed'
      end

      test 'adds language class when provided' do
        render_inline(CodeBlock.new(language: 'ruby')) { 'def test; end' }

        assert_selector 'code.language-ruby'
      end

      test 'does not add language class when not provided' do
        render_inline(CodeBlock.new) { 'code' }

        assert_selector 'code:not([class*="language-"])'
      end

      test 'preserves whitespace and line breaks' do
        code = "def example\n  puts 'hello'\nend"
        render_inline(CodeBlock.new) { code }

        assert_selector 'code', text: code
      end

      test 'preserves indentation' do
        code = "  indented\n    more indented"
        render_inline(CodeBlock.new) { code }

        assert_selector 'code', text: code
      end

      test 'escapes HTML content' do
        render_inline(CodeBlock.new) { '<script>alert("xss")</script>' }

        assert_selector 'code', text: '<script>alert("xss")</script>'
      end

      test 'merges custom classes on pre element' do
        render_inline(CodeBlock.new(class: 'custom-block')) { 'Test' }

        assert_selector 'pre.custom-block.bg-slate-900'
      end

      test 'accepts additional HTML attributes on pre element' do
        render_inline(CodeBlock.new(id: 'code-example', data: { syntax: 'ruby' })) { 'Test' }

        assert_selector 'pre#code-example[data-syntax="ruby"]'
      end

      test 'supports multiple languages' do
        %w[ruby javascript python html css].each do |lang|
          render_inline(CodeBlock.new(language: lang)) { 'code' }

          assert_selector "code.language-#{lang}"
        end
      end
    end
  end
end
