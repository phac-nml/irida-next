# frozen_string_literal: true

module Pathogen
  module Form
    # Shared accessibility helpers for Checkbox component
    module CheckboxAccessibility
      private

      # Renders enhanced description for select-all style checkboxes
      def enhanced_description_html
        return ''.html_safe if @controls.blank?

        description_text = case @attribute.to_s
                           when /select.*all|select.*page/
                             t('pathogen.form.checkbox_accessibility.select_page')
                           when /select.*row/
                             t('pathogen.form.checkbox_accessibility.select_row')
                           end

        return ''.html_safe unless description_text

        tag.span(
          description_text,
          id: "#{input_id}_description",
          class: 'sr-only',
          'aria-live': 'polite'
        )
      end

      # Validates that accessibility requirements are met
      def validate_accessibility_requirements!
        return unless @label.blank? && @aria_label.blank? && @aria_labelledby.blank?

        raise ArgumentError,
              "Checkbox requires either 'label', 'aria_label', or 'aria_labelledby' for accessibility compliance"
      end

      # Renders checkbox with only aria-label (no visible label)
      def render_aria_only_checkbox
        tag.div(class: 'flex flex-col') do
          checkbox_html +
            tag.div(class: 'mt-1') do
              help_text_sr_only_html + enhanced_description_html
            end
        end
      end

      # Renders checkbox with visible label
      def render_labeled_checkbox
        tag.div(class: 'flex flex-col') do
          tag.div(class: 'flex items-center gap-3') do
            checkbox_html + label_html
          end +
            tag.div(class: 'mt-1 ml-8') do
              help_html + enhanced_description_html
            end
        end
      end

      # Renders help text in screen reader only mode when no visible label
      def help_text_sr_only_html
        if @help_text.present?
          tag.span(@help_text, id: help_text_id, class: 'sr-only', 'aria-live': 'polite')
        else
          ''.html_safe
        end
      end
    end
  end
end
