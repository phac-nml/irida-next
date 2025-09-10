# frozen_string_literal: true

module Pathogen
  module Form
    # Utility module for rendering checkbox component HTML.
    #
    # This module provides focused methods for generating the different
    # types of HTML output needed for checkbox components, including
    # input elements, labels, and help text.
    #
    # @api private
    # @since 1.0.0
    module CheckboxRenderer
      # Merges form attributes with enhanced ARIA support.
      #
      # Overrides the base FormHelper method to add checkbox-specific
      # ARIA attributes and role information.
      #
      # @return [Hash] enhanced form attributes with ARIA support
      def form_attributes
        attributes = super
        attributes[:aria] = merged_aria(attributes[:aria])
        attributes[:role] = @role if @role.present?
        attributes
      end

      private

      # Merges ARIA attributes with existing attributes.
      #
      # Combines provided ARIA attributes with component-specific ones,
      # handling describedby relationships and control associations.
      #
      # @param existing_aria [Hash, nil] existing ARIA attributes
      # @return [Hash] merged ARIA attributes
      def merged_aria(existing_aria)
        # Merge precedence: existing_aria (from callers) <- @aria_user (nested) <- component vars
        aria = existing_aria ? existing_aria.dup : {}
        aria = aria.merge(@aria_user) if @aria_user.is_a?(Hash)

        assign_if_present(aria, :label, @aria_label)
        assign_if_present(aria, :labelledby, @aria_labelledby)
        assign_if_present(aria, :live, @aria_live)

        if @controls.present?
          aria[:controls] = @controls
          aria[:describedby] = join_describedby(aria[:describedby])
        end

        aria
      end

      # Determines if the component should re-render based on argument changes.
      #
      # Implements basic memoization to skip unnecessary re-renders when
      # the component arguments haven't changed since the last render.
      #
      # @return [Boolean] true if component should render, false to skip
      def should_render?
        @last_render_args != [@form, @attribute, @value, @options]
      end

      # Stores current render arguments for comparison in next render cycle.
      #
      # Called before rendering to capture the current state for
      # comparison in future render cycles to enable memoization.
      #
      # @return [void]
      def before_render
        @last_render_args = [@form, @attribute, @value, @options.dup]
      end
    end
  end
end
