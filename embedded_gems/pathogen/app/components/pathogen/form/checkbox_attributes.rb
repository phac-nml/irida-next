# frozen_string_literal: true

module Pathogen
  module Form
    # Utility module for building HTML attributes for checkbox components.
    #
    # This module provides focused methods for constructing the various types
    # of HTML attributes needed for accessible checkbox inputs, including
    # base attributes, ARIA attributes, and describedby relationships.
    #
    # @api private
    # @since 1.0.0
    module CheckboxAttributes
      # Builds the complete set of HTML attributes for the checkbox input.
      #
      # Combines base HTML attributes with ARIA attributes for accessibility.
      # This is the main entry point for attribute construction.
      #
      # @return [Hash] complete hash of HTML attributes for the checkbox input
      def attributes
        base_attributes.merge(additional_attributes)
      end

      private

      # Builds the base HTML attributes for the checkbox input.
      #
      # Includes standard form input attributes like type, id, name, value,
      # checked state, disabled state, and CSS classes.
      #
      # @return [Hash] hash of base HTML attributes
      def base_attributes
        {
          type: 'checkbox',
          id: input_id,
          name: input_name,
          value: @value,
          checked: @checked,
          disabled: @disabled,
          class: input_classes(@class)
        }
      end

      # Builds additional attributes including ARIA and optional attributes.
      #
      # Combines ARIA attributes, role, onchange handler, and any additional
      # HTML options provided by the user.
      #
      # @return [Hash] hash of additional HTML attributes
      def additional_attributes
        attrs = {}

        # Add ARIA attributes if any exist
        aria_attrs = build_aria_attributes
        attrs[:aria] = aria_attrs unless aria_attrs.empty?

        # Add role if present
        attrs[:role] = @role if @role.present?

        # Add onchange if present
        attrs[:onchange] = @onchange if @onchange.present?

        # Merge with any additional HTML options
        attrs.merge(@html_options || {})
      end

      # Builds ARIA attributes for accessibility.
      #
      # Constructs the aria hash with label, labelledby, live, controls,
      # and describedby attributes based on component configuration.
      #
      # @return [Hash] hash of ARIA attributes
      def build_aria_attributes
        aria_attrs = {}

        build_basic_aria_attributes(aria_attrs)
        build_describedby_attributes(aria_attrs)

        aria_attrs
      end

      # Builds basic ARIA attributes (label, labelledby, live, controls).
      #
      # @param aria_attrs [Hash] the ARIA attributes hash to populate
      # @return [Hash] the modified ARIA attributes hash
      def build_basic_aria_attributes(aria_attrs)
        assign_if_present(aria_attrs, :label, @aria_label)
        assign_if_present(aria_attrs, :labelledby, @aria_labelledby)
        assign_if_present(aria_attrs, :live, @aria_live)
        assign_if_present(aria_attrs, :controls, @controls)

        aria_attrs
      end

      # Builds describedby attributes for help text and related elements.
      #
      # Handles the complex logic for combining help text IDs, existing
      # described_by values, and controls describedby relationships.
      #
      # @param aria_attrs [Hash] the ARIA attributes hash to populate
      # @return [Hash] the modified ARIA attributes hash
      def build_describedby_attributes(aria_attrs)
        add_help_text_describedby(aria_attrs)
        add_existing_describedby(aria_attrs)
        add_controls_describedby(aria_attrs)

        aria_attrs
      end

      # Adds help text ID to aria-describedby if help text is present.
      #
      # @param aria_attrs [Hash] the ARIA attributes hash to modify
      # @return [void]
      def add_help_text_describedby(aria_attrs)
        return if @help_text.blank?

        aria_attrs[:describedby] = help_text_id
      end

      # Adds existing described_by value to aria-describedby.
      #
      # @param aria_attrs [Hash] the ARIA attributes hash to modify
      # @return [void]
      def add_existing_describedby(aria_attrs)
        return if @described_by.blank?

        existing = aria_attrs[:describedby]
        aria_attrs[:describedby] = [existing, @described_by].compact.join(' ')
      end

      # Adds controls describedby to aria-describedby if controls are present.
      #
      # @param aria_attrs [Hash] the ARIA attributes hash to modify
      # @return [void]
      def add_controls_describedby(aria_attrs)
        return if @controls.blank?

        existing = aria_attrs[:describedby]
        aria_attrs[:describedby] = join_describedby(existing)
      end
    end
  end
end
