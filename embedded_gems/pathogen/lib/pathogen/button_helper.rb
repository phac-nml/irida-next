# frozen_string_literal: true

module Pathogen
  # Helper methods for rendering Pathogen buttons
  module ButtonHelper
    # Renders a Pathogen::Button component with the given options and block
    #
    # @param scheme [Symbol] The color scheme (default, primary, danger, ghost, unstyled)
    # @param options [Hash] Additional options to pass to the button
    # @yield [c] The button component for adding visual elements
    # @yieldparam c [Pathogen::Button] The button component
    # @return [String] HTML for the rendered button
    def p_button(scheme: :default, **, &)
      render(Pathogen::Button.new(scheme: scheme, **), &)
    end
  end
end
