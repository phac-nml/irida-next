# test/components/previews/pathogen/form/check_box_tag_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    # Preview for Pathogen::Form::CheckBoxTag component
    #
    # This component renders standalone checkbox inputs with Pathogen styling.
    # It follows the exact Rails check_box_tag helper signature and behavior.
    #
    # Each preview method corresponds to an HTML template file in the
    # test/components/previews/pathogen/form/check_box_tag_preview/ directory.
    class CheckBoxTagPreview < ViewComponent::Preview
      # @!group Basic Examples

      # @label Default Checkbox
      # Basic standalone checkbox with default Pathogen styling
      def default; end

      # @label With Custom Value
      # Checkbox with custom value instead of default '1'
      def with_custom_value; end

      # @label Checked State
      # Checkbox that is pre-checked
      def checked_state; end

      # @!endgroup

      # @!group With Options

      # @label With ID and Classes
      # Checkbox with custom ID and CSS classes
      def with_id_and_classes; end

      # @label With ARIA Labels
      # Checkbox with accessibility attributes
      def with_aria_labels; end

      # @label With Data Attributes
      # Checkbox with Stimulus data attributes for JavaScript interactivity
      def with_data_attributes; end

      # @label Disabled State
      # Checkbox that is disabled and cannot be modified
      def disabled_state; end

      # @!endgroup

      # @!group Array Fields

      # @label Multiple Checkboxes (Array Pattern)
      # Multiple checkboxes using array naming convention
      def multiple_checkboxes_array; end

      # @label Select All Pattern
      # Master checkbox with subordinate checkboxes for bulk selection
      def select_all_pattern; end

      # @!endgroup

      # @!group Real-World Examples

      # @label Workflow Step Selection
      # Real-world example of checkbox usage in workflow step selection
      def workflow_step_selection; end

      # @!endgroup

      # @!group Without Hidden Field

      # @label Without Hidden Field
      # Checkbox that excludes the hidden field Rails normally includes
      def without_hidden_field; end

      # @!endgroup

      # @!group Edge Cases

      # @label Empty String Value
      # Checkbox with empty string as value
      def empty_string_value; end

      # @label Special Characters in Name
      # Checkbox with nested attribute naming containing special characters
      def special_characters_name; end

      # @label Long Value
      # Checkbox with very long value string
      def long_value; end

      # @!endgroup
    end
  end
end
