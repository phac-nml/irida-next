# frozen_string_literal: true

# Accessible radio button component for Rails forms with WCAG AAA compliance.
#
# This ViewComponent renders a fully accessible radio button input with proper
# label association, ARIA attributes, and TailwindCSS styling. It supports
# both standalone usage and integration with Rails form builders.
#
# @example Basic usage with visible label
#   <%= render Pathogen::Form::RadioButton.new(
#     attribute: :theme,
#     value: "dark",
#     label: "Dark Theme",
#     help_text: "A dark color scheme for better readability."
#   ) %>
#
# @example With Rails form builder
#   <%= form_with model: @user do |form| %>
#     <%= render Pathogen::Form::RadioButton.new(
#       form: form,
#       attribute: :theme,
#       value: "system",
#       label: "System Theme"
#     ) %>
#   <% end %>
#
# @example Radio button without visible label (for fieldset groups)
#   <%= render Pathogen::Form::RadioButton.new(
#     attribute: :theme,
#     value: "light",
#     aria: { label: "Light theme option" },
#     help_text: "A bright color scheme"
#   ) %>
#
# @since 1.0.0
# @version 2.0.0

module Pathogen
  module Form
    # Accessible radio button component for Rails forms.
    #
    # A clean, maintainable radio button component that extends BaseFormComponent
    # with radio-specific rendering and styling. Supports both labeled and
    # unlabeled configurations for use within fieldsets.
    #
    # @example Basic radio button with visible label
    #   <%= render Pathogen::Form::RadioButton.new(
    #     attribute: :theme,
    #     value: "dark",
    #     label: "Dark Theme",
    #     help_text: "A dark color scheme for better readability"
    #   ) %>
    #
    # @example With form builder
    #   <%= form_with model: @user do |form| %>
    #     <%= render Pathogen::Form::RadioButton.new(
    #       form: form,
    #       attribute: :theme,
    #       value: "system",
    #       label: "System Theme"
    #     ) %>
    #   <% end %>
    #
    # @example Radio button without visible label (for fieldset groups)
    #   <%= render Pathogen::Form::RadioButton.new(
    #     attribute: :theme,
    #     value: "light"
    #   ) %>
    #
    # @since 1.0.0
    # @version 2.0.0
    class RadioButton < BaseFormComponent
      include RadioButtonStyles

      protected

      # Renders the radio button component HTML.
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def render_component
        if @label.blank?
          radio_button_input_html
        else
          render_labeled_layout
        end
      end

      # Provides CSS classes for the radio button input element.
      #
      # @param user_class [String, nil] additional CSS classes from user
      # @return [String] complete CSS class string for the input
      def input_classes(user_class = nil)
        radio_button_classes(user_class)
      end

      # Returns the input type for radio buttons.
      #
      # @return [String] the input type
      def input_type
        'radio'
      end

      private

      # Renders layout for radio buttons with visible labels.
      #
      # @return [ActiveSupport::SafeBuffer] the labeled radio button HTML
      def render_labeled_layout
        tag.div(class: radio_button_container_classes) do
          tag.div(class: radio_button_input_container_classes) do
            radio_button_input_html + label_html
          end +
            tag.div(class: radio_button_help_container_classes) do
              help_text_html
            end
        end
      end

      # Renders the radio button input element.
      #
      # @return [ActiveSupport::SafeBuffer] the radio button input HTML
      def radio_button_input_html
        radio_button_tag(
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

      # Renders help text if present.
      #
      # @return [ActiveSupport::SafeBuffer] the help text HTML or empty string
      def help_text_html
        return ''.html_safe if @help_text.blank?

        tag.span(@help_text, id: help_text_id, class: help_text_classes)
      end
    end
  end
end
