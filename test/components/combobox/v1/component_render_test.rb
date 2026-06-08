# frozen_string_literal: true

require 'view_component_test_case'

module Combobox
  module V1
    class ComponentRenderTest < ViewComponentTestCase
      include ActionView::Helpers::FormOptionsHelper

      test 'renders default combobox role and aria state' do
        render_component

        assert_selector 'input[role="combobox"][aria-autocomplete="list"][aria-expanded="false"]'
      end

      test 'passes through aria attributes' do
        render_component(
          aria: {
            required: true,
            invalid: true,
            describedby: 'field-error'
          }
        )

        assert_selector 'input[aria-required="true"][aria-invalid="true"][aria-describedby="field-error"]'
      end

      test 'renders aria-disabled only for disabled options' do
        render_component(options: options_with_disabled)

        assert_selector '[role="option"][data-value="enabled-option"]:not([aria-disabled])'
        assert_selector '[role="option"][data-value="disabled-option"][aria-disabled="true"]'
      end

      test 'renders clear and show-options buttons outside tab order' do
        render_component

        assert_selector 'button[data-combobox--v1-target="indicatorClearButton"][tabindex="-1"]'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][tabindex="-1"]'
      end

      test 'renders combobox input with aria-disabled and indicator buttons disabled when disabled is true' do
        render_component(disabled: true)

        assert_selector 'input[role="combobox"][aria-disabled="true"]:not([disabled])'
        assert_selector 'button[data-combobox--v1-target="indicatorClearButton"][disabled]'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][disabled]'
      end

      test 'default preview renders' do
        render_combobox_preview(:default)

        assert_selector 'input[role="combobox"]'
      end

      test 'with_disabled_options preview renders aria-disabled options' do
        render_combobox_preview(:with_disabled_options)

        assert_selector '[role="option"][data-value="disabled-option"][aria-disabled="true"]'
      end

      test 'disabled preview renders disabled combobox' do
        render_combobox_preview(:disabled)

        assert_selector 'input[role="combobox"][aria-disabled="true"]:not([disabled])'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][disabled]'
      end

      private

      def render_component(options: default_options, **)
        render_inline(
          ComboboxComponent.new(
            form: build_form_builder,
            field: :field,
            options: options,
            **
          )
        )
      end

      def build_form_builder
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        object = Struct.new(:field).new(nil)
        ActionView::Helpers::FormBuilder.new(:search, object, template, {})
      end

      def default_options
        options_for_select([['Enabled option', 'enabled-option']])
      end

      def options_with_disabled
        options_for_select(
          [['Enabled option', 'enabled-option'], ['Disabled option', 'disabled-option']],
          { disabled: ['disabled-option'] }
        )
      end

      def render_combobox_preview(name)
        ViewComponent::TestCase.instance_method(:render_preview).bind_call(
          self,
          name,
          from: ComboboxComponentPreview,
          params: {}
        )
      end
    end
  end
end
