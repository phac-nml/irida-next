# frozen_string_literal: true

module Pathogen
  # Provides helper methods for easily rendering `Pathogen::Button` components within Rails views.
  module ButtonHelper
    # Renders a `Pathogen::Button` component with the specified options and content.
    # This helper simplifies the instantiation and rendering of button components.
    #
    # @param scheme [Symbol] The color scheme for the button. Determines its appearance
    #   (e.g., :default, :primary, :danger).
    #   Refer to `Pathogen::Button::SCHEME_OPTIONS` for available schemes.
    # @param options [Hash] A hash of options to be passed directly to the `Pathogen::Button` component's initializer.
    #   This can include attributes like `disabled`, `block`, `class`, `id`, HTML `data` attributes,
    #   and other HTML attributes. For example, `disabled: true`, `class: 'my-custom-button'`.
    # @yield [button_component] If a block is given, it will be passed to the `Pathogen::Button` component.
    #   This allows for adding content or visual elements (e.g., icons via `leading_visual` or
    #   `trailing_visual`) to the button.
    # @yieldparam button_component [Pathogen::Button] The instance of the button component, allowing for configuration
    #   within the block (e.g., adding icons).
    # @return [String] The HTML string representing the rendered button component.
    #
    # @example Basic button with text
    #   <%= p_button { "Click Me" } %>
    #
    # @example Primary button with an icon
    #   <%= p_button scheme: :primary, data: { turbo_frame: '_top' } do |btn| %>
    #     <% btn.leading_visual icon: :plus %>
    #     Create New
    #   <% end %>
    #
    # @example Disabled danger button
    #   <%= p_button scheme: :danger, disabled: true { "Delete" } %>
    #
    # @example Unstyled button with custom classes
    #   <%= p_button scheme: :unstyled, class: 'font-bold p-4' { "Learn More" } %>
    def p_button(scheme: :default, **, &)
      render(Pathogen::Button.new(scheme: scheme, **), &)
    end
  end
end
