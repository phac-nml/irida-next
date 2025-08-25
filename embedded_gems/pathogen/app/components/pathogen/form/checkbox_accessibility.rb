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
                             'Selects or deselects all items on this page'
                           when /select.*row/
                             'Selects or deselects this specific row'
                           end

        return ''.html_safe unless description_text

        tag.span(
          description_text,
          id: "#{input_id}_description",
          class: 'sr-only',
          'aria-live': 'polite'
        )
      end
    end
  end
end
