# test/components/previews/pathogen/form/check_box_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    # Preview for Pathogen::Form::CheckBox component
    #
    # This component renders checkbox inputs for Rails form builders with Pathogen styling.
    # It follows the exact Rails form.check_box helper signature and behavior.
    #
    # Each preview method corresponds to an HTML template file in the
    # test/components/previews/pathogen/form/check_box_preview/ directory.
    class CheckBoxPreview < ViewComponent::Preview
      # @!group Basic Form Examples

      # @label Default Form Checkbox
      # Basic checkbox with default Pathogen styling
      def default; end

      # @label With Custom Values
      # Checkbox with custom checked and unchecked values
      def with_custom_values; end

      # @label Checked State
      # Checkbox that is pre-checked
      def checked_state; end

      # @!endgroup

      # @!group With HTML Options

      # @label With ID and Classes
      # Checkbox with custom ID and CSS classes
      def with_id_and_classes; end

      # @label With ARIA Attributes
      # Checkbox with accessibility attributes
      def with_aria_attributes; end

      # @label With Data Attributes
      # Checkbox with Stimulus data attributes for JavaScript interactivity
      def with_data_attributes; end

      # @label Disabled State
      # Checkbox that is disabled and cannot be modified
      def disabled_state; end

      # @!endgroup

      # @!group Different Value Types

      # @label Boolean Field
      # Checkbox bound to a boolean field on a model object
      def boolean_field; end

      # @label String Values
      # Checkbox using string values for checked/unchecked states
      def string_values; end

      # @label Numeric Values
      # Checkbox using numeric string values
      def numeric_values; end

      # @!endgroup

      # @!group Complex Form Scenarios

      # @label Multiple Checkboxes in Form
      # Multiple checkboxes organized in fieldsets within a single form
      def multiple_checkboxes_form; end

      # @label Nested Attributes
      # Checkboxes within nested form attributes using fields_for
      def nested_attributes; end

      # @!endgroup

      # @!group Without Hidden Field

      # @label Without Hidden Field
      # Checkbox that excludes the hidden field Rails normally includes
      def without_hidden_field; end

      # @!endgroup

      # @!group Error States

      # @label With Form Errors
      # Checkbox with validation errors displayed
      def with_form_errors; end

      # @!endgroup
    end
  end
end
