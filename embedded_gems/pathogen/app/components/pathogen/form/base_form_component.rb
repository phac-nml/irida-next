# frozen_string_literal: true

module Pathogen
  module Form
    # Base class for all form components providing shared functionality.
    #
    # This class consolidates common form component behavior including:
    # - Input naming and ID generation
    # - ARIA attribute handling
    # - Option extraction and validation
    # - Basic HTML attribute construction
    #
    # @abstract Subclass and implement {#render_component} and {#input_classes}
    # @since 2.0.0
    class BaseFormComponent < ViewComponent::Base
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::TranslationHelper
      include FormStyles

      # Initializes the base form component with common attributes.
      #
      # @param attribute [Symbol] the model attribute name
      # @param value [String] the input value
      # @param form [ActionView::Helpers::FormBuilder, nil] optional form builder
      # @param options [Hash] component options
      def initialize(attribute:, value:, form: nil, **options)
        super()
        @form = form
        @attribute = attribute
        @value = value
        extract_and_validate_options!(options)
      end

      # Renders the form component.
      #
      # @abstract Subclasses must implement this method
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def call
        render_component
      end

      protected

      # Template method for subclasses to implement their rendering logic.
      #
      # @abstract
      # @return [ActiveSupport::SafeBuffer] the rendered HTML
      def render_component
        raise NotImplementedError, "#{self.class} must implement #render_component"
      end

      # Template method for subclasses to provide input-specific CSS classes.
      #
      # @abstract
      # @param user_class [String, nil] additional user-provided classes
      # @return [String] CSS class string
      def input_classes(user_class = nil)
        raise NotImplementedError, "#{self.class} must implement #input_classes"
      end

      # Generates the input name for form submission.
      #
      # @return [String] the input name
      def input_name
        return @input_name if @input_name.present?
        return "#{@form.object_name}[#{@attribute}]" if @form&.object_name.present?

        @attribute.to_s
      end

      # Generates a unique ID for the input element.
      #
      # @return [String] the input ID
      def input_id
        return @id if @id.present?

        base = if @form&.object_name.present?
                 "#{@form.object_name}_#{@attribute}_#{@value}"
               else
                 "#{input_name}_#{@value}"
               end
        base.gsub(/[\[\]]+/, '_').chomp('_')
      end

      # Generates a unique ID for help text elements.
      #
      # @return [String] the help text ID
      def help_text_id
        @help_text_id ||= "#{input_id}_help"
      end

      # Builds complete form attributes for the input element.
      #
      # @return [Hash] HTML attributes hash
      def form_attributes
        base_attributes.merge(aria_attributes).merge(additional_attributes)
      end

      private

      # Extracts options from the constructor and validates requirements.
      #
      # @param options [Hash] the options to extract
      # @return [void]
      def extract_and_validate_options!(options)
        extract_basic_options!(options)
        extract_accessibility_options!(options)
        extract_behavior_options!(options)
        @html_options = options # Store any remaining options
        validate_accessibility_requirements!
      end

      # Extracts basic form options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_basic_options!(options)
        @input_name = options.delete(:input_name)
        @id = options.delete(:id)
        @label = options.delete(:label)
        @checked = options.delete(:checked) || false
        @disabled = options.delete(:disabled) || false
        @class = options.delete(:class)
        @help_text = options.delete(:help_text)
        @error_text = options.delete(:error_text)
      end

      # Extracts accessibility-related options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_accessibility_options!(options)
        @role = options.delete(:role)
        process_aria_options!(options)
      end

      # Extracts behavior and interaction options.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def extract_behavior_options!(options)
        @lang = options.delete(:lang)
        @onchange = options.delete(:onchange)
        @selected_message = options.delete(:selected_message)
        @deselected_message = options.delete(:deselected_message)
      end

      # Processes nested ARIA options and sets instance variables.
      #
      # @param options [Hash] the options hash to modify
      # @return [void]
      def process_aria_options!(options)
        aria = options.delete(:aria)
        return unless aria.is_a?(Hash)

        aria = aria.transform_keys(&:to_sym)
        @aria_label = aria[:label]
        @aria_labelledby = aria[:labelledby]
        @aria_describedby = aria[:describedby]
        @aria_live = aria[:live]
        @controls = aria[:controls]
      end

      # Validates that accessibility requirements are met.
      #
      # @raise [ArgumentError] if no accessible label is provided
      # @return [void]
      def validate_accessibility_requirements!
        return unless @label.blank? && @aria_label.blank? && @aria_labelledby.blank?

        raise ArgumentError,
              "Form component requires either 'label', " \
              "'aria: { label: ... }', or 'aria: { labelledby: ... }' " \
              'for accessibility compliance'
      end

      # Builds base HTML attributes.
      #
      # @return [Hash] base attributes hash
      def base_attributes
        {
          type: input_type,
          id: input_id,
          name: input_name,
          value: @value,
          checked: @checked,
          disabled: @disabled,
          class: input_classes(@class)
        }.compact
      end

      # Builds ARIA attributes hash.
      #
      # @return [Hash] ARIA attributes hash
      def aria_attributes
        aria = {}
        
        aria[:label] = @aria_label if @aria_label.present?
        aria[:labelledby] = @aria_labelledby if @aria_labelledby.present?
        aria[:live] = @aria_live if @aria_live.present?
        aria[:controls] = @controls if @controls.present?
        
        # Build describedby from multiple sources
        describedby_parts = [
          @aria_describedby,
          (@help_text.present? ? help_text_id : nil),
          (@controls.present? ? "#{input_id}_description" : nil)
        ].compact

        aria[:describedby] = describedby_parts.join(' ') if describedby_parts.any?

        aria.any? ? { aria: aria } : {}
      end

      # Builds additional HTML attributes.
      #
      # @return [Hash] additional attributes hash
      def additional_attributes
        attrs = {}
        attrs[:role] = @role if @role.present?
        attrs[:onchange] = @onchange if @onchange.present?
        # Note: lang attribute not applied to form inputs per existing behavior
        attrs.merge(@html_options || {})
      end

      # Returns the input type for this component.
      #
      # @abstract Subclasses should override if not checkbox
      # @return [String] the input type
      def input_type
        'checkbox'
      end

      # Assigns a value to a hash if the value is present.
      #
      # @param hash [Hash] the hash to modify
      # @param key [Symbol, String] the key to set
      # @param value [Object] the value to assign if present
      # @return [Hash] the modified hash
      def assign_if_present(hash, key, value)
        return hash if value.blank?

        hash[key] = value
        hash
      end
    end
  end
end