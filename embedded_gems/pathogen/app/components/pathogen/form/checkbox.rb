# frozen_string_literal: true

# Bare bones checkbox component that only renders the checkbox input with Pathogen styling.
#
# This component renders just the checkbox input element with consistent Pathogen styling,
# exactly like Rails' check_box helper but with our design system styling.
#
# @example Basic usage exactly like Rails check_box helper
#   <%= render Pathogen::Form::Checkbox.new("post", "validated") %>
#   # Same as: check_box("post", "validated")
#
# @example With custom values like Rails check_box
#   <%= render Pathogen::Form::Checkbox.new("puppy", "good_dog", {}, "yes", "no") %>
#   # Same as: check_box("puppy", "good_dog", {}, "yes", "no")
#
# @example With HTML options like Rails check_box
#   <%= render Pathogen::Form::Checkbox.new("eula", "accepted", { class: 'eula_check' }, "yes", "no") %>
#   # Same as: check_box("eula", "accepted", { class: 'eula_check' }, "yes", "no")
#
# @example With Rails form builder exactly like f.check_box
#   <%= form_with model: @user do |form| %>
#     <%= render Pathogen::Form::Checkbox.new(:newsletter, {}, "1", "0", form: form) %>
#     # Same as: form.check_box(:newsletter)
#   <% end %>
#
# @since 1.0.0
# @version 3.0.0
module Pathogen
  module Form
    # Bare bones checkbox component for Rails forms.
    #
    # Renders only the checkbox input element with Pathogen styling, no labels or help text.
    # Behaves exactly like Rails' check_box helper but with consistent design system styling.
    #
    # @since 1.0.0
    # @version 3.0.0
    # rubocop:disable Metrics/ClassLength
    class Checkbox < ViewComponent::Base
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper

      # Initialize checkbox component to exactly match Rails check_box helper signature
      #
      # Supports these calling patterns:
      # 1. check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
      # 2. form.check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      #
      # @param object_name_or_method [Symbol, String] object name (standalone) or method name (form builder)
      # @param method_or_options [Symbol, String, Hash] method name (standalone) or options (form builder)
      # @param options_or_checked_value [Hash, String] options hash (standalone) or checked_value (form builder)
      # @param checked_value_or_unchecked_value [String] checked_value (standalone) or unchecked_value (form builder)
      # @param unchecked_value [String] unchecked_value (standalone only)
      # @param form [ActionView::Helpers::FormBuilder, nil] form builder for form.check_box pattern
      # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(object_name_or_method, method_or_options = {}, options_or_checked_value = {},
                     checked_value_or_unchecked_value = '1', unchecked_value = '0', form: nil, **)
        super()

        if form.present?
          # Form builder pattern: form.check_box(method, options, checked_value, unchecked_value)
          @method = object_name_or_method
          @object_name = nil
          @form = form
          options = method_or_options || {}
          @checked_value = options_or_checked_value.is_a?(Hash) ? '1' : options_or_checked_value.to_s
          @unchecked_value = checked_value_or_unchecked_value.is_a?(Hash) ? '0' : checked_value_or_unchecked_value.to_s
        else
          # Standalone pattern: check_box(object_name, method, options, checked_value, unchecked_value)
          @object_name = object_name_or_method
          @method = method_or_options
          @form = nil
          options = options_or_checked_value || {}
          @checked_value = checked_value_or_unchecked_value.to_s
          @unchecked_value = unchecked_value.to_s
        end

        # For field name patterns, the "method" is actually the value
        @checked_value = @method.to_s if @object_name.present? && field_name_pattern?

        # Extract Rails-specific options
        @checked = options.delete(:checked)
        @include_hidden = options.delete(:include_hidden) { true }

        # Store remaining HTML options for the input
        @html_options = options || {}
      end
      # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Renders the checkbox component HTML - just the input with styling
      #
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def call
        if @form.present?
          render_form_builder_checkbox
        elsif @object_name.present? && !field_name_pattern?
          render_rails_helper_checkbox
        else
          render_fallback_checkbox
        end
      end

      private

      # Checks if the object_name is actually a field name pattern.
      #
      # Field names like "sample_ids[]", "select-page", etc. should use check_box_tag
      # rather than the Rails check_box helper which expects model object names.
      #
      # @return [Boolean] true if this appears to be a field name rather than object name
      def field_name_pattern?
        return false if @object_name.blank?

        # Detect array field patterns like "sample_ids[]", "attachment_ids[]"
        # or direct field names like "select-page"
        @object_name.to_s.match?(/\[\]$|^[\w-]+$/)
      end

      # Renders checkbox using Rails form builder conventions but avoids recursion.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox HTML
      def render_form_builder_checkbox
        html = ''.html_safe
        html += render_hidden_field if @include_hidden != false
        html += render_form_checkbox_tag
        html
      end

      # Renders the checkbox tag for form builder pattern
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox tag HTML
      def render_form_checkbox_tag
        attrs = build_checkbox_tag_attributes
        attrs[:name] = "#{@form.object_name}[#{@method}]"
        attrs[:id] = "#{@form.object_name}_#{@method}" unless attrs[:id].present?
        tag.input(**attrs)
      end

      # Renders checkbox using Rails form helper with proper naming.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox HTML
      def render_rails_helper_checkbox
        rails_options = build_rails_options
        check_box(@object_name, @method, rails_options, @checked_value, @unchecked_value)
      end

      # Renders checkbox using check_box_tag as fallback.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox HTML
      def render_fallback_checkbox
        html = ''.html_safe
        html += render_hidden_field if @include_hidden != false
        html += render_checkbox_tag
        html
      end

      # Builds options hash for Rails helpers with Pathogen styling.
      #
      # @return [Hash] merged options for Rails helper
      def build_rails_options
        rails_options = {
          class: checkbox_classes
        }

        rails_options[:id] = input_id if input_id.present?
        rails_options[:checked] = @checked if @checked.present?

        remaining_options = @html_options.except(:class, :id, :checked)
        rails_options.merge(remaining_options)
      end

      # Provides CSS classes for the checkbox input element with Pathogen styling.
      #
      # @return [String] complete CSS class string for the input
      # rubocop:disable Metrics/MethodLength
      def checkbox_classes
        base_classes = [
          'size-6',
          'text-primary-600',
          'bg-slate-100',
          'border-slate-300',
          'rounded',
          'dark:bg-slate-700',
          'dark:border-slate-600',
          'cursor-pointer'
        ]

        user_classes = @html_options[:class]

        if user_classes.present?
          "#{base_classes.join(' ')} #{user_classes}"
        else
          base_classes.join(' ')
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Generates input ID based on Rails conventions
      #
      # @return [String, nil] the input ID
      def input_id
        return @html_options[:id] if @html_options[:id].present?
        return "#{@form.object_name}_#{@method}" if @form&.object_name.present?
        return "#{@object_name}_#{@method}" if @object_name.present? && !field_name_pattern?

        nil
      end

      # Generates input name based on Rails conventions
      #
      # @return [String] the input name
      def input_name
        return "#{@form.object_name}[#{@method}]" if @form&.object_name.present?
        return @object_name.to_s if field_name_pattern?
        return "#{@object_name}[#{@method}]" if @object_name.present?

        @method.to_s
      end

      # Renders the hidden field for unchecked value.
      #
      # @return [ActiveSupport::SafeBuffer] the hidden field HTML
      def render_hidden_field
        hidden_name = if @form.present?
                        "#{@form.object_name}[#{@method}]"
                      else
                        input_name
                      end
        tag.input(type: 'hidden', name: hidden_name, value: @unchecked_value)
      end

      # Renders the checkbox tag using Rails' original implementation.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox tag HTML
      def render_checkbox_tag
        tag.input(**build_checkbox_tag_attributes)
      end

      # Builds all attributes for the checkbox tag
      #
      # @return [Hash] attributes for the checkbox input tag
      def build_checkbox_tag_attributes
        attrs = build_rails_options
        attrs[:type] = 'checkbox'
        attrs[:name] = input_name
        attrs[:value] = @checked_value
        attrs[:checked] = 'checked' if @checked
        attrs
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
