# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class IconHelperTest < ActionView::TestCase
    include Pathogen::IconHelper

    test 'render_icon with string name' do
      result = render_icon('clipboard-text')
      assert_match(/<svg/, result)
    end

    test 'render_icon with symbol name' do
      result = render_icon(:check)
      assert_match(/<svg/, result)
    end

    test 'render_icon with options' do
      result = render_icon('check', class: 'custom-class')
      assert_match(/custom-class/, result)
    end

    test 'render_icon with legacy hash format for backward compatibility' do
      legacy_hash = { name: 'clipboard-text', options: { class: 'legacy-class' } }
      result = render_icon(legacy_hash)
      assert_match(/<svg/, result)
      assert_match(/legacy-class/, result)
    end

    test 'render_icon merges legacy options with user options' do
      legacy_hash = { name: 'check', options: { class: 'legacy-class' } }
      result = render_icon(legacy_hash, class: 'user-class')
      assert_match(/legacy-class/, result)
      assert_match(/user-class/, result)
    end

    test 'render_icon sets aria-hidden by default' do
      result = render_icon('check')
      assert_match(/aria-hidden="true"/, result)
    end

    test 'render_icon preserves existing aria-hidden' do
      result = render_icon('check', 'aria-hidden': false)
      assert_match(/aria-hidden="false"/, result)
    end

    test 'render_icon works with ICON constants for backward compatibility' do
      # This assumes ICON::CHECK is still defined in legacy_icon_constants.rb
      result = render_icon(ICON::CHECK)
      assert_match(/<svg/, result)
    end

    private

    # Mock the rails_icons icon method for testing
    def icon(name, **options)
      aria_hidden = options['aria-hidden'] || options[:'aria-hidden']
      css_class = options[:class] || options['class'] || ''
      content = "<svg class=\"#{css_class}\" aria-hidden=\"#{aria_hidden}\">#{name}</svg>"
      content.html_safe
    end
  end
end