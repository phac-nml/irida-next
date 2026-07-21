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

      test 'renders slot options and selected slot value' do
        render_component do |combobox|
          combobox.with_option(value: 'enabled-option', label: 'Enabled option')
          combobox.with_option(value: 'disabled-option', label: 'Disabled option', disabled: true)
          combobox.with_option(value: 'selected-option', label: 'Selected option', selected: true)
        end

        assert_selector '[role="option"][data-value="enabled-option"]', visible: :all
        assert_selector '[role="option"][data-value="disabled-option"][aria-disabled="true"]', visible: :all
        assert_selector 'input[role="combobox"][value="Selected option"]'
        assert_selector 'input[type="hidden"][value="selected-option"]', visible: :all
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

        assert_selector '[role="option"][data-value="enabled-option"]:not([aria-disabled])', visible: :all
        assert_selector '[role="option"][data-value="disabled-option"][aria-disabled="true"]', visible: :all
      end

      test 'renders clear and show-options buttons outside tab order' do
        render_component

        assert_selector 'button[data-combobox--v1-target="indicatorClearButton"][tabindex="-1"]'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][tabindex="-1"]'
      end

      test 'renders combobox input with aria-disabled and indicator buttons disabled when disabled is true' do
        render_component(disabled: true)

        assert_selector 'input[role="combobox"][aria-disabled="true"][readonly]:not([disabled])'
        assert_selector 'button[data-combobox--v1-target="indicatorClearButton"][aria-disabled="true"]:not([disabled])'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][aria-disabled="true"]:not([disabled])'
      end

      test 'default preview renders' do
        render_combobox_preview(:default)

        assert_selector 'input[role="combobox"]'
      end

      test 'with_disabled_options preview renders aria-disabled options' do
        render_combobox_preview(:with_disabled_options)

        assert_selector '[role="option"][data-value="second-disabled-option"][aria-disabled="true"]', visible: :all
      end

      test 'disabled preview renders disabled combobox' do
        render_combobox_preview(:disabled)

        assert_selector 'input[role="combobox"][aria-disabled="true"][readonly]:not([disabled])'
        assert_selector 'button[data-combobox--v1-target="indicatorButton"][aria-disabled="true"]:not([disabled])'
      end

      test 'with_slots preview renders slot options' do
        render_combobox_preview(:with_slots)

        assert_selector 'input[role="combobox"][value="User 3"]'
        assert_selector '[role="option"][data-value="3"]', visible: :all
        assert_selector '[role="option"][data-value="5"][aria-disabled="true"]', visible: :all
      end

      private

      def render_component(options: default_options, **component_arguments, &)
        render_inline(
          ComboboxComponent.new(
            form: build_form_builder,
            field: :field,
            options: options,
            **component_arguments
          ),
          &
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
