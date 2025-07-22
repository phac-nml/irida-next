# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

module Pathogen
  # rubocop:disable Metrics/ClassLength
  # Test suite for FormHelpers module functionality
  class FormHelpersTest < Minitest::Test
    include Pathogen::FormHelper

    # Test class that includes FormHelpers for testing
    class TestComponent
      include Pathogen::FormHelper
      attr_reader :form, :attribute, :value, :options

      def initialize(attribute:, form: nil, value: nil, **options)
        @form = form
        @attribute = attribute
        @value = value
        extract_options!(options)
      end

      # Stub input_classes for testing
      def input_classes(user_class)
        "stub-classes #{user_class}".strip
      end
    end

    def setup
      @form = Struct.new(:object_name).new('user')
      @component = TestComponent.new(form: @form, attribute: :email)
    end

    def test_help_text_id_generates_unique_id
      assert_equal 'user_email_help', @component.help_text_id
    end

    def test_input_name_uses_form_builder_when_available
      assert_equal 'user[email]', @component.input_name
    end

    def test_input_name_uses_direct_attribute_when_no_form
      component = TestComponent.new(attribute: :email)
      assert_equal 'email', component.input_name
    end

    def test_input_name_uses_custom_input_name_when_provided
      component = TestComponent.new(attribute: :email, input_name: 'custom_name')
      assert_equal 'custom_name', component.input_name
    end

    def test_input_id_generates_unique_id_with_form
      component = TestComponent.new(form: @form, attribute: :email, value: 'test')
      assert_equal 'user_email_test', component.input_id
    end

    def test_input_id_generates_unique_id_without_form
      component = TestComponent.new(attribute: :email, value: 'test')
      assert_equal 'email_test', component.input_id
    end

    def test_input_id_handles_array_notation
      component = TestComponent.new(form: @form, attribute: 'email[]', value: 'test')
      assert_equal 'user_email__test', component.input_id
    end

    def test_form_attributes_includes_all_necessary_attributes
      component = TestComponent.new(
        form: @form,
        attribute: :email,
        disabled: true,
        described_by: 'desc',
        help_text: 'Help text',
        class: 'custom-class',
        onchange: 'handleChange()'
      )

      attributes = component.form_attributes

      assert attributes[:disabled]
      assert_includes attributes[:class], 'custom-class'
      assert_equal 'desc user_email_help', attributes[:aria][:describedby]
      assert_equal(-1, attributes[:tabindex])
      assert_equal 'handleChange()', attributes[:onchange]
    end

    def test_aria_attributes_includes_all_necessary_attributes
      component = TestComponent.new(
        form: @form,
        attribute: :email,
        disabled: true,
        described_by: 'desc',
        controls: 'controls'
      )

      attributes = component.aria_attributes

      assert_equal 'true', attributes[:disabled]
      assert_equal 'desc', attributes[:describedby]
      assert_equal 'controls', attributes[:controls]
    end

    def test_extract_options_assigns_all_options_correctly
      options = {
        input_name: 'custom_name',
        label: 'Email',
        checked: true,
        disabled: true,
        described_by: 'desc',
        controls: 'controls',
        lang: 'en',
        onchange: 'handleChange()',
        help_text: 'Help text',
        class: 'custom-class',
        data: { test: 'value' }
      }

      component = TestComponent.new(form: @form, attribute: :email, **options)
      assert_option_assignments(component)
    end

    private

    def assert_option_assignments(component)
      assert_basic_options(component)
      assert_aria_options(component)
      assert_html_options(component)
    end

    def assert_basic_options(component)
      assert_equal 'custom_name', component.instance_variable_get(:@input_name)
      assert_equal 'Email', component.instance_variable_get(:@label)
      assert component.instance_variable_get(:@checked)
      assert component.instance_variable_get(:@disabled)
    end

    def assert_aria_options(component)
      assert_equal 'desc', component.instance_variable_get(:@described_by)
      assert_equal 'controls', component.instance_variable_get(:@controls)
      assert_equal 'en', component.instance_variable_get(:@lang)
    end

    def assert_html_options(component)
      assert_equal 'handleChange()', component.instance_variable_get(:@onchange)
      assert_equal 'Help text', component.instance_variable_get(:@help_text)
      assert_equal 'custom-class', component.instance_variable_get(:@user_class)
      assert_equal({ data: { test: 'value' } }, component.instance_variable_get(:@html_options))
    end

    def test_form_attributes_handles_nil_values_correctly
      component = TestComponent.new(form: @form, attribute: :email)
      attributes = component.form_attributes

      assert_equal false, attributes[:disabled]
      assert_nil attributes[:aria][:describedby]
      assert_equal 0, attributes[:tabindex]
      assert_nil attributes[:onchange]
    end

    def test_aria_attributes_handles_nil_values_correctly
      component = TestComponent.new(form: @form, attribute: :email)
      attributes = component.aria_attributes

      assert_equal 'false', attributes[:disabled]
      assert_nil attributes[:describedby]
      assert_nil attributes[:controls]
    end
  end
  # rubocop:enable Metrics/ClassLength
end
