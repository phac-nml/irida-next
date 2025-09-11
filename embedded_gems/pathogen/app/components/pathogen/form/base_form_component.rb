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
      include FormAriaHelper
      include FormOptionExtractor

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

      # Builds additional HTML attributes.
      #
      # @return [Hash] additional attributes hash
      def additional_attributes
        attrs = {}
        attrs[:role] = @role if @role.present?
        attrs[:onchange] = @onchange if @onchange.present?
        # NOTE: lang attribute not applied to form inputs per existing behavior
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
