# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class Tabs
    # Test suite for Pathogen::Tabs::LazyPanel component
    # Validates eager/lazy rendering and W3C/ARIA compliance
    # rubocop:disable Metrics/ClassLength
    class LazyPanelTest < ViewComponent::TestCase
      test 'renders eager turbo frame when selected' do
        render_inline(Pathogen::Tabs::LazyPanel.new(
                        frame_id: 'content-frame',
                        src_path: '/path/to/content',
                        selected: true
                      )) do
          '<p>Eager content</p>'.html_safe
        end

        assert_selector 'turbo-frame#content-frame'
        assert_text 'Eager content'
        assert_no_selector 'turbo-frame[src]'
        assert_no_selector 'turbo-frame[loading]'
      end

      test 'renders lazy turbo frame when not selected' do
        render_inline(Pathogen::Tabs::LazyPanel.new(
                        frame_id: 'content-frame',
                        src_path: '/path/to/content',
                        selected: false
                      )) do
          '<p>This should not render</p>'.html_safe
        end

        assert_selector 'turbo-frame#content-frame[src="/path/to/content"]'
        assert_selector 'turbo-frame[loading="lazy"]'
        assert_selector 'turbo-frame[refresh="morph"]'
        assert_no_text 'This should not render'
      end

      test 'uses custom refresh strategy' do
        render_inline(Pathogen::Tabs::LazyPanel.new(
                        frame_id: 'content-frame',
                        src_path: '/path/to/content',
                        selected: false,
                        refresh: 'replace'
                      )) do
          'Content'
        end

        assert_selector 'turbo-frame[refresh="replace"]'
      end

      test 'requires frame_id parameter' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            src_path: '/path',
            selected: true
          )
        end
        assert_equal 'missing keyword: :frame_id', error.message
      end

      test 'requires src_path parameter' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            frame_id: 'frame',
            selected: true
          )
        end
        assert_equal 'missing keyword: :src_path', error.message
      end

      test 'requires selected parameter' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            frame_id: 'frame',
            src_path: '/path'
          )
        end
        assert_equal 'missing keyword: :selected', error.message
      end

      test 'raises error if frame_id is blank' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            frame_id: '',
            src_path: '/path',
            selected: true
          )
        end
        assert_equal 'frame_id is required', error.message
      end

      test 'raises error if src_path is blank' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            frame_id: 'frame',
            src_path: '',
            selected: true
          )
        end
        assert_equal 'src_path is required', error.message
      end

      test 'raises error if selected is not boolean' do
        error = assert_raises(ArgumentError) do
          Pathogen::Tabs::LazyPanel.new(
            frame_id: 'frame',
            src_path: '/path',
            selected: 'true'
          )
        end
        assert_equal 'selected must be a boolean', error.message
      end

      test 'render_eager? returns true when selected' do
        component = Pathogen::Tabs::LazyPanel.new(
          frame_id: 'frame',
          src_path: '/path',
          selected: true
        )

        assert component.render_eager?
      end

      test 'render_eager? returns false when not selected' do
        component = Pathogen::Tabs::LazyPanel.new(
          frame_id: 'frame',
          src_path: '/path',
          selected: false
        )

        assert_not component.render_eager?
      end

      test 'eager rendering includes complex HTML content' do
        render_inline(Pathogen::Tabs::LazyPanel.new(
                        frame_id: 'content-frame',
                        src_path: '/path',
                        selected: true
                      )) do
          '<div><h2>Title</h2><p>Paragraph</p></div>'.html_safe
        end

        assert_selector 'turbo-frame#content-frame'
        assert_selector 'h2', text: 'Title'
        assert_selector 'p', text: 'Paragraph'
      end

      test 'lazy frame is empty' do
        render_inline(Pathogen::Tabs::LazyPanel.new(
                        frame_id: 'content-frame',
                        src_path: '/path',
                        selected: false
                      )) do
          'Content'
        end

        # Frame should exist but be empty
        assert_selector 'turbo-frame#content-frame'
        frame_content = page.find('turbo-frame#content-frame').text.strip
        assert_empty frame_content
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
