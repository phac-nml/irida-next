# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class IconHelperTest < ActiveSupport::TestCase
    include IconHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Context

    # Mock the icon method that would come from Rails Icons
    def icon(name, **)
      content_tag(:svg, '', **, data: { icon: name })
    end

    # Mock class_names helper that handles both strings and hashes
    def class_names(*args)
      classes = []
      args.each do |arg|
        if arg.is_a?(Hash)
          arg.each { |k, v| classes << k.to_s if v }
        elsif arg
          classes << arg.to_s
        end
      end
      classes.join(' ')
    end

    test 'render_icon with ICON constant hash' do
      result = render_icon(ICON::CLIPBOARD)
      assert_includes result, 'data-icon="clipboard-text"'
      assert_includes result, 'aria-hidden="true"'
    end

    test 'render_icon with ICON constant hash and additional options' do
      result = render_icon(ICON::CLIPBOARD, class: 'h-5 w-5 text-primary-600')
      assert_includes result, 'data-icon="clipboard-text"'
      assert_includes result, 'h-5 w-5 text-primary-600'
      assert_includes result, 'aria-hidden="true"'
    end

    test 'render_icon with symbol key (legacy)' do
      result = render_icon(:clipboard)
      assert_includes result, 'data-icon="clipboard-text"'
      assert_includes result, 'aria-hidden="true"'
    end

    test 'render_icon with string key (legacy)' do
      result = render_icon('clipboard')
      assert_includes result, 'data-icon="clipboard-text"'
      assert_includes result, 'aria-hidden="true"'
    end

    test 'render_icon with heroicons library option' do
      result = render_icon(ICON::BEAKER)
      assert_includes result, 'data-icon="beaker"'
      assert_includes result, 'library="heroicons"'
    end

    test 'render_icon with loading icon includes animate-spin class' do
      result = render_icon(ICON::LOADING)
      assert_includes result, 'data-icon="spinner-gap"'
      assert_includes result, 'animate-spin'
    end

    test 'render_icon with TOKEN icon includes variant option' do
      result = render_icon(ICON::TOKEN)
      assert_includes result, 'data-icon="poker-chip"'
      assert_includes result, 'variant="duotone"'
    end

    test 'render_icon returns nil for unknown symbol' do
      result = render_icon(:unknown_icon)
      assert_nil result
    end

    test 'render_icon returns nil for unknown string' do
      result = render_icon('unknown_icon')
      assert_nil result
    end

    test 'render_icon returns nil for invalid hash without name' do
      result = render_icon({ invalid: 'hash' })
      assert_nil result
    end

    test 'render_icon returns nil for nil input' do
      result = render_icon(nil)
      assert_nil result
    end

    test 'render_icon merges base options with user options' do
      # Create a custom icon definition for testing
      custom_icon = { name: 'test-icon', options: { library: :heroicons, variant: :solid } }
      result = render_icon(custom_icon, class: 'custom-class', variant: :outline)

      assert_includes result, 'data-icon="test-icon"'
      assert_includes result, 'library="heroicons"'
      assert_includes result, 'variant="outline"' # user option should override base option
      assert_includes result, 'custom-class'
    end

    test 'render_icon preserves aria-hidden when explicitly provided as string key' do
      result = render_icon(ICON::CLIPBOARD, 'aria-hidden' => false)
      assert_includes result, 'aria-hidden="false"'
    end

    test 'render_icon preserves aria-hidden when explicitly provided as symbol key' do
      result = render_icon(ICON::CLIPBOARD, 'aria-hidden': false)
      assert_includes result, 'aria-hidden="false"'
    end

    test 'render_icon warns about and removes data attributes' do
      # Capture warnings
      warnings = []
      original_warn = method(:warn)
      define_singleton_method(:warn) { |msg| warnings << msg }

      result = render_icon(ICON::CLIPBOARD, 'data-test' => 'value', 'data_other' => 'value2')

      # Restore original warn method
      define_singleton_method(:warn, original_warn)

      assert_equal 1, warnings.length
      assert_includes warnings.first, '[icon_helper] data attributes'
      assert_includes warnings.first, 'data-test'
      assert_includes warnings.first, 'data_other'

      # Data attributes should be removed from result
      assert_not_includes result, 'data-test'
      assert_not_includes result, 'data_other'
    end

    test 'render_icon handles class merging correctly' do
      # Test with base class from icon definition
      custom_icon = { name: 'test-icon', options: { class: 'base-class' } }
      result = render_icon(custom_icon, class: 'user-class')

      assert_includes result, 'class="base-class user-class'
    end

    test 'merge_icon_classes includes icon name class in non-production environment' do
      original_env = Rails.env
      Rails.env = 'development'

      # Test that class_names is called with the proper hash structure for development
      # This indirectly tests the merge_icon_classes logic
      expected_result = class_names('base-class', 'user-class', { 'test-icon-icon' => true })
      result = send(:merge_icon_classes, 'base-class', 'user-class', 'test-icon')
      assert_equal expected_result, result

      Rails.env = original_env
    end

    test 'merge_icon_classes excludes icon name class in production environment' do
      original_env = Rails.env
      Rails.env = 'production'

      # In production, the hash should contain false for the icon name class
      result = send(:merge_icon_classes, 'base-class', 'user-class', 'test-icon')
      # Our mock will include empty strings for false values, so test the opposite behavior
      expected_result = class_names('base-class', 'user-class', { 'test-icon-icon' => false })
      assert_equal expected_result, result

      Rails.env = original_env
    end

    test 'ICON module constants are properly defined' do
      assert_equal 'arrow-up', ICON::ARROW_UP[:name]
      assert_equal({}, ICON::ARROW_UP[:options])
      assert ICON::ARROW_UP.frozen?
    end

    test 'ICON module DEFINITIONS hash contains all constants' do
      # Test that DEFINITIONS contains lowercase symbol keys for all constants
      assert_includes ICON::DEFINITIONS.keys, :clipboard
      assert_equal ICON::CLIPBOARD, ICON::DEFINITIONS[:clipboard]
    end

    test 'ICON module bracket accessor works with symbols' do
      assert_equal ICON::CLIPBOARD, ICON[:clipboard]
    end

    test 'ICON module bracket accessor works with strings' do
      assert_equal ICON::CLIPBOARD, ICON['clipboard']
    end

    test 'ICON module bracket accessor returns nil for unknown keys' do
      assert_nil ICON[:unknown]
      assert_nil ICON['unknown']
    end

    test 'global ICON constant is accessible' do
      assert_equal Pathogen::ICON, ICON
    end

    test 'resolve_icon_definition with hash containing name' do
      icon_def = { name: 'test', options: {} }
      assert_equal icon_def, send(:resolve_icon_definition, icon_def)
    end

    test 'resolve_icon_definition with hash missing name' do
      icon_def = { options: {} }
      assert_nil send(:resolve_icon_definition, icon_def)
    end

    test 'resolve_icon_definition with symbol' do
      result = send(:resolve_icon_definition, :clipboard)
      assert_equal ICON::CLIPBOARD, result
    end

    test 'resolve_icon_definition with string' do
      result = send(:resolve_icon_definition, 'clipboard')
      assert_equal ICON::CLIPBOARD, result
    end

    test 'resolve_icon_definition with unknown symbol' do
      assert_nil send(:resolve_icon_definition, :unknown)
    end

    test 'prepare_icon_options merges options correctly' do
      icon_def = { name: 'test', options: { library: :heroicons, class: 'base-class' } }
      user_options = { variant: :solid, class: 'user-class' }

      result = send(:prepare_icon_options, icon_def, user_options)

      assert_equal :heroicons, result[:library]
      assert_equal :solid, result[:variant]
      assert_includes result[:class], 'base-class'
      assert_includes result[:class], 'user-class'
      assert_equal true, result['aria-hidden']
    end

    test 'clean_data_attributes! removes data attributes and warns' do
      options = { class: 'test', 'data-test' => 'value', 'data_other' => 'value2' }

      # Capture warnings
      warnings = []
      original_warn = method(:warn)
      define_singleton_method(:warn) { |msg| warnings << msg }

      send(:clean_data_attributes!, options)

      # Restore original warn method
      define_singleton_method(:warn, original_warn)

      assert_equal 1, warnings.length
      assert_includes warnings.first, '[icon_helper] data attributes'

      assert_equal({ class: 'test' }, options)
    end

    test 'clean_data_attributes! does nothing when no data attributes present' do
      options = { class: 'test', variant: :solid }
      original_options = options.dup

      # Should not warn
      warnings = []
      original_warn = method(:warn)
      define_singleton_method(:warn) { |msg| warnings << msg }

      send(:clean_data_attributes!, options)

      # Restore original warn method
      define_singleton_method(:warn, original_warn)

      assert_empty warnings
      assert_equal original_options, options
    end

    test 'ensure_aria_hidden! adds aria-hidden when not present' do
      options = { class: 'test' }
      send(:ensure_aria_hidden!, options)
      assert_equal true, options['aria-hidden']
    end

    test 'ensure_aria_hidden! does not override existing aria-hidden string key' do
      options = { 'aria-hidden' => false }
      send(:ensure_aria_hidden!, options)
      assert_equal false, options['aria-hidden']
    end

    test 'ensure_aria_hidden! does not override existing aria-hidden symbol key' do
      options = { 'aria-hidden': false }
      send(:ensure_aria_hidden!, options)
      assert_equal false, options[:'aria-hidden']
    end

    test 'merge_icon_options excludes class from both base and user options' do
      base_options = { library: :heroicons, class: 'base-class', variant: :solid }
      user_options = { variant: :outline, class: 'user-class', size: :lg }

      result = send(:merge_icon_options, base_options, user_options)

      assert_equal :heroicons, result[:library]
      assert_equal :outline, result[:variant] # user option overrides base
      assert_equal :lg, result[:size]
      assert_not_includes result.keys, :class
    end

    test 'merge_icon_classes combines base and user classes with icon name class in development' do
      original_env = Rails.env
      Rails.env = 'development'

      result = send(:merge_icon_classes, 'base-class', 'user-class', 'test-icon')
      assert_includes result, 'base-class'
      assert_includes result, 'user-class'
      # In development, the icon name class is added via a hash argument
      # Our mock class_names helper will include it
      expected_result = class_names('base-class', 'user-class', { 'test-icon-icon' => true })
      assert_equal expected_result, result

      Rails.env = original_env
    end

    test 'build_test_selector with ICON constant hash' do
      result = send(:build_test_selector, ICON::CLIPBOARD)
      # The method finds the first constant that matches the hash value
      # In this case it might find DETAILS first since they both use 'clipboard-text'
      assert result.is_a?(String)
      assert_includes %w[CLIPBOARD DETAILS], result
    end

    test 'build_test_selector with unknown hash returns name' do
      custom_hash = { name: 'custom-icon', options: {} }
      result = send(:build_test_selector, custom_hash)
      assert_equal 'custom-icon', result
    end

    test 'build_test_selector with symbol' do
      result = send(:build_test_selector, :clipboard)
      assert_equal 'clipboard', result
    end

    test 'build_test_selector with string' do
      result = send(:build_test_selector, 'clipboard')
      assert_equal 'clipboard', result
    end

    test 'build_test_selector with object that responds to to_s' do
      obj = Object.new
      def obj.to_s
        'custom_object'
      end

      result = send(:build_test_selector, obj)
      assert_equal 'custom_object', result
    end
  end
end
