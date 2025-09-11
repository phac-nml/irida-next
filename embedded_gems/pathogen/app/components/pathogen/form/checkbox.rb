# frozen_string_literal: true

# Accessible checkbox component for Rails forms with WCAG AAA compliance.
#
# This ViewComponent renders a fully accessible checkbox input with proper
# label association, ARIA attributes, and TailwindCSS styling. It supports
# both standalone usage and integration with Rails form builders.
#
# @example Basic usage with visible label
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :terms,
#     value: "1",
#     label: "I agree to the terms",
#     help_text: "You must agree to continue."
#   ) %>
#
# @example With Rails form builder
#   <%= form_with model: @user do |form| %>
#     <%= render Pathogen::Form::Checkbox.new(
#       form: form,
#       attribute: :newsletter,
#       value: "1",
#       label: "Subscribe to newsletter"
#     ) %>
#   <% end %>
#
# @example Screen reader only label (aria.label)
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :select_all,
#     value: "1",
#     aria: { label: "Select all items on this page" },
#     help_text: "Check to select all items, uncheck to deselect all"
#   ) %>
#
# @example Using aria.labelledby for external labeling
#   <h3 id="bulk-actions-heading">Bulk Actions</h3>
#   <%= render Pathogen::Form::Checkbox.new(
#     attribute: :select_all,
#     value: "1",
#     aria: { labelledby: "bulk-actions-heading" },
#     help_text: "Select all items for bulk operations"
#   ) %>
#
# @note This component requires either a `label`, `aria: { label: ... }`, or `aria: { labelledby: ... }` parameter
#   for accessibility compliance.
#
# @since 1.0.0
# @version 2.0.0
module Pathogen
  module Form
    # Accessible checkbox component for Rails forms.
    #
    # A clean, maintainable checkbox component that extends BaseFormComponent
    # with checkbox-specific rendering and styling. Supports both labeled and
    # aria-only configurations with full accessibility compliance.
    #
    # @example Basic checkbox with visible label
    #   <%= render Pathogen::Form::Checkbox.new(
    #     attribute: :terms,
    #     value: "1",
    #     label: "I agree to the terms and conditions"
    #   ) %>
    #
    # @example With form builder and help text
    #   <%= form_with model: @user do |form| %>
    #     <%= render Pathogen::Form::Checkbox.new(
    #       form: form,
    #       attribute: :newsletter,
    #       value: "1",
    #       label: "Subscribe to newsletter",
    #       help_text: "We'll send you updates about new features"
    #     ) %>
    #   <% end %>
    #
    # @example Screen reader accessible (no visible label)
    #   <%= render Pathogen::Form::Checkbox.new(
    #     attribute: :select_all,
    #     value: "1",
    #     aria: { label: "Select all items in the table" },
    #     help_text: "Toggle to select or deselect all items"
    #   ) %>
    #
    # @since 1.0.0
    # @version 2.0.0
    class Checkbox < BaseFormComponent
      include CheckboxStyles

      protected

      # Renders the checkbox component HTML.
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def render_component
        tag.div(class: checkbox_container_classes) do
          if @label.blank?
            render_aria_only_layout
          else
            render_labeled_layout
          end
        end
      end

      # Provides CSS classes for the checkbox input element.
      #
      # @param user_class [String, nil] additional CSS classes from user
      # @return [String] complete CSS class string for the input
      def input_classes(user_class = nil)
        checkbox_classes(user_class)
      end

      private

      # Renders layout for checkboxes with visible labels.
      #
      # @return [ActiveSupport::SafeBuffer] the labeled checkbox HTML
      def render_labeled_layout
        content = tag.div(class: checkbox_input_container_classes) do
          checkbox_input_html + label_html
        end

        help_content = help_text_html
        description_content = description_html

        # Only render help container if there's actual content to display
        if help_content || description_content
          content += tag.div(class: checkbox_help_container_classes) do
            (help_content || ''.html_safe) + (description_content || ''.html_safe)
          end
        end

        content
      end

      # Renders layout for aria-only checkboxes (no visible label).
      #
      # @return [ActiveSupport::SafeBuffer] the aria-only checkbox HTML
      def render_aria_only_layout
        checkbox_input_html +
          tag.div(class: checkbox_aria_help_container_classes) do
            (help_text_sr_only_html || ''.html_safe) + (description_html || ''.html_safe)
          end
      end

      # Renders the checkbox input element.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox input HTML
      def checkbox_input_html
        check_box_tag(
          input_name,
          @value,
          @checked,
          form_attributes.merge(@html_options || {})
        )
      end

      # Renders the label element if label text is present.
      #
      # @return [ActiveSupport::SafeBuffer, nil] the label HTML or nil
      def label_html
        return if @label.blank?

        tag.label(@label, for: input_id, class: label_classes)
      end

      # Renders visible help text.
      #
      # @return [ActiveSupport::SafeBuffer, nil] the help text HTML or nil
      def help_text_html
        return nil if @help_text.blank?

        tag.span(@help_text, id: help_text_id, class: help_text_classes)
      end

      # Renders screen reader only help text.
      #
      # @return [ActiveSupport::SafeBuffer, nil] the sr-only help text HTML or nil
      def help_text_sr_only_html
        return nil if @help_text.blank?

        tag.span(
          @help_text,
          id: help_text_id,
          class: help_text_sr_only_classes,
          'aria-live': 'polite'
        )
      end

      # Renders enhanced description for special checkbox types.
      #
      # @return [ActiveSupport::SafeBuffer, nil] the description HTML or nil
      def description_html
        return nil if @controls.blank?

        description_text = case @attribute.to_s
                           when /select.*all|select.*page/
                             t('pathogen.form.checkbox_accessibility.select_page')
                           when /select.*row/
                             t('pathogen.form.checkbox_accessibility.select_row')
                           end

        return nil unless description_text

        tag.span(
          description_text,
          id: "#{input_id}_description",
          class: description_classes,
          'aria-live': 'polite'
        )
      end

      # Checks if this checkbox should have an enhanced description.
      #
      # @return [Boolean] true if enhanced description should be rendered
      def enhanced_description?
        return false if @controls.blank?

        @attribute.to_s.match?(/select.*all|select.*page|select.*row/)
      end
    end
  end
end
