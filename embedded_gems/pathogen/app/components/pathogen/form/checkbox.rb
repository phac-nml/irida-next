# frozen_string_literal: true

# Accessible checkbox component for Rails forms with WCAG AAA compliance.
#
# This ViewComponent renders a fully accessible checkbox input with proper
# label association, ARIA attributes, and TailwindCSS styling. It supports
# both standalone usage and integration with Rails form builders.
#
# @example Basic usage exactly like Rails check_box helper
#   <%= render Pathogen::Form::Checkbox.new("post", "validated") %>
#   # Same as: check_box("post", "validated")
#
# @example With custom values like Rails check_box
#   <%= render Pathogen::Form::Checkbox.new("puppy", "gooddog", {}, "yes", "no") %>
#   # Same as: check_box("puppy", "gooddog", {}, "yes", "no")
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
# @example With form builder and custom values
#   <%= form_with model: @user do |form| %>
#     <%= render Pathogen::Form::Checkbox.new(:active, { class: 'status-check' }, "yes", "no", form: form) %>
#     # Same as: form.check_box(:active, { class: 'status-check' }, "yes", "no")
#   <% end %>
#
# @example With accessibility features (pathogen enhancement)
#   <%= render Pathogen::Form::Checkbox.new("select", "all", {
#     label: "Select all items",
#     aria: { label: "Select all items on this page" },
#     help_text: "Check to select all items"
#   }) %>
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
    # @example Basic checkbox exactly like Rails check_box helper
    #   <%= render Pathogen::Form::Checkbox.new("post", "validated") %>
    #
    # @example With form builder exactly like f.check_box
    #   <%= form_with model: @user do |form| %>
    #     <%= render Pathogen::Form::Checkbox.new(:newsletter, {
    #       label: "Subscribe to newsletter",
    #       help_text: "We'll send you updates about new features"
    #     }, "1", "0", form: form) %>
    #   <% end %>
    #
    # @example Screen reader accessible (pathogen enhancement)
    #   <%= render Pathogen::Form::Checkbox.new("select", "all", {
    #     aria: { label: "Select all items in the table" },
    #     help_text: "Toggle to select or deselect all items"
    #   }) %>
    #
    # @since 1.0.0
    # @version 2.0.0
    # rubocop:disable Metrics/ClassLength
    class Checkbox < BaseFormComponent
      include CheckboxStyles

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
      # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength, Metrics/AbcSize
      def initialize(object_name_or_method, method_or_options = {}, options_or_checked_value = {},
                     checked_value_or_unchecked_value = '1', unchecked_value = '0', form: nil, **)
        if form.present?
          # Form builder pattern: form.check_box(method, options, checked_value, unchecked_value)
          @method = object_name_or_method
          @object_name = nil
          options = method_or_options || {}
          @checked_value = options_or_checked_value.is_a?(Hash) ? '1' : options_or_checked_value.to_s
          @unchecked_value = checked_value_or_unchecked_value.is_a?(Hash) ? '0' : checked_value_or_unchecked_value.to_s
        else
          # Standalone pattern: check_box(object_name, method, options, checked_value, unchecked_value)
          @object_name = object_name_or_method
          @method = method_or_options
          options = options_or_checked_value || {}
          @checked_value = checked_value_or_unchecked_value.to_s
          @unchecked_value = unchecked_value.to_s
        end

        # For field name patterns, the "method" is actually the value
        if @object_name.present? && field_name_pattern_at_init?
          @checked_value = @method.to_s
        end

        # Extract accessibility options from options hash
        label = options.delete(:label)
        help_text = options.delete(:help_text)
        aria = options.delete(:aria) || {}

        # Extract Rails-specific options
        checked = options.delete(:checked)
        @include_hidden = options.delete(:include_hidden) { true }

        # Store HTML options separately since parent will extract them
        @stored_html_options = options

        # Call parent with transformed parameters - BaseFormComponent expects keyword arguments
        super(
          attribute: @method,
          value: @checked_value,
          form: form,
          label: label,
          help_text: help_text,
          aria: aria,
          checked: checked,
          include_hidden: @include_hidden,
          **options # Pass HTML options directly to parent for extraction
        )
      end
      # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength, Metrics/AbcSize

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
        return render_form_builder_checkbox if @form.present?
        return render_rails_helper_checkbox if @object_name.present? && !field_name_pattern?

        render_fallback_checkbox
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

      # Override input_name for field name patterns.
      #
      # When using field name patterns like "sample_ids[]", the object_name
      # IS the field name, not a model object name that needs construction.
      #
      # @return [String] the input name
      def input_name
        return @input_name if @input_name.present?
        return "#{@form.object_name}[#{@attribute}]" if @form&.object_name.present?
        return @object_name.to_s if field_name_pattern?

        @attribute.to_s
      end

      # Checks field name pattern during initialization (before @attribute is set).
      #
      # @return [Boolean] true if this appears to be a field name rather than object name
      def field_name_pattern_at_init?
        return false if @object_name.blank?

        @object_name.to_s.match?(/\[\]$|^[\w-]+$/)
      end

      # Renders checkbox using Rails form builder.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox HTML
      def render_form_builder_checkbox
        @form.check_box(@method, @html_options || {}, @checked_value, @unchecked_value)
      end

      # Renders checkbox using Rails form helper with proper naming.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox HTML
      def render_rails_helper_checkbox
        user_class = @stored_html_options[:class] if @stored_html_options
        rails_options = build_rails_options(user_class)
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

      # Builds options hash for Rails check_box helper.
      #
      # @param user_class [String, nil] additional CSS classes from user
      # @return [Hash] merged options for Rails helper
      def build_rails_options(user_class)
        rails_options = {
          id: input_id,
          class: input_classes(user_class)
        }
        remaining_options = (@html_options || {}).except(:class)
        rails_options.merge(remaining_options)
      end

      # Renders the hidden field for unchecked value.
      #
      # @return [ActiveSupport::SafeBuffer] the hidden field HTML
      def render_hidden_field
        hidden_field_tag(input_name, @unchecked_value, id: nil)
      end

      # Renders the checkbox tag.
      #
      # @return [ActiveSupport::SafeBuffer] the checkbox tag HTML
      def render_checkbox_tag
        check_box_tag(
          input_name,
          @checked_value,
          @checked,
          form_attributes.merge(@html_options || {})
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
