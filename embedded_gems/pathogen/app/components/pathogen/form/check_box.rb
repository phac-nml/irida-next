# frozen_string_literal: true

# Rails form checkbox component for Pathogen design system.
#
# This component renders only the checkbox input element with Pathogen styling
# for Rails form builder usage (form.check_box). It follows the exact signature
# and behavior of Rails' form.check_box helper.
#
# @example Basic usage with form builder
#   <%= form_with model: @user do |form| %>
#     <%= form.check_box(:newsletter) %>
#   <% end %>
#
# @example With custom values
#   <%= form_with model: @user do |form| %>
#     <%= form.check_box(:newsletter, {}, "yes", "no") %>
#   <% end %>
#
# @since 3.1.0
module Pathogen
  module Form
    # Rails form checkbox component.
    #
    # Renders only the checkbox input element with Pathogen styling for Rails forms.
    # Always uses Rails object[method] naming conventions.
    #
    # @since 3.1.0
    class CheckBox < ViewComponent::Base
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include CheckboxStyling

      # Initialize checkbox component for Rails form builder
      #
      # @param method [Symbol, String] the method name
      # @param options [Hash] HTML options for the checkbox
      # @param checked_value [String] value when checked (default: "1")
      # @param unchecked_value [String] value when unchecked (default: "0")
      # @param form [ActionView::Helpers::FormBuilder] the form builder instance
      def initialize(method, options = {}, checked_value = '1', unchecked_value = '0', form:)
        super()

        @method = method
        @form = form
        @checked_value = checked_value.to_s
        @unchecked_value = unchecked_value.to_s

        # Extract Rails-specific options
        options ||= {}
        @checked = options.delete(:checked)
        @include_hidden = options.delete(:include_hidden) { true }

        # Store remaining HTML options for the input
        @html_options = options
      end

      # Renders the checkbox component HTML - just the input with styling
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def call
        html = ''.html_safe
        html += render_hidden_field(input_name, @unchecked_value) if @include_hidden != false
        html += render_checkbox_input
        html
      end

      private

      # Renders the checkbox input element
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox input HTML
      def render_checkbox_input
        attrs = build_checkbox_attributes
        attrs[:name] = input_name
        attrs[:value] = @checked_value
        attrs[:id] = input_id if input_id.present?

        tag.input(**attrs)
      end

      # Generates input name using Rails conventions: object[method]
      #
      # @return [String] the input name
      def input_name
        "#{@form.object_name}[#{@method}]"
      end

      # Generates input ID using Rails conventions: object_method
      #
      # @return [String, nil] the input ID
      def input_id
        return @html_options[:id] if @html_options[:id].present?

        "#{@form.object_name}_#{@method}"
      end
    end
  end
end
