# frozen_string_literal: true

module Pathogen
  # Pathogen::Icon renders Phosphor icons, providing a consistent interface for their use.
  # It wraps the `phosphor_icon` helper (often aliased as `helpers.icon`),
  # allowing specification of icon name, variant, size, and other HTML attributes.
  # This component benefits from the underlying helper's performance optimizations, such as icon caching.
  #
  # @example Basic usage
  #   <%= render Pathogen::Icon.new(icon: :plus) %>
  #
  # @example With variant and size
  #   <%= render Pathogen::Icon.new(icon: :arrow_right, variant: :bold, size: '24px') %>
  #
  # @example With additional classes
  #   <%= render Pathogen::Icon.new(icon: :user, class: 'text-primary-500') %>
  #
  class Icon < Pathogen::Component
    erb_template <<-ERB
      <%# The underlying icon helper is expected to handle nil icon_name gracefully.
          The @icon_name.present? check ensures we only attempt to render if an icon name is resolved. %>
      <% if @icon_name.present? %>
        <%= helpers.icon(@icon_name, **@system_arguments) %>
      <% end %>
    ERB

    # Initializes the Icon component.
    #
    # @param icon [Symbol, String, nil] The name of the Phosphor icon to render (e.g., :plus, 'arrow-right').
    #   If nil or blank, no icon will be rendered.
    # @param variant [Symbol] The icon variant (e.g., :regular, :thin, :light, :bold, :fill, :duotone).
    #   Defaults to :regular. This is passed as an option to the underlying icon helper.
    # @param system_arguments [Hash] Additional HTML attributes to be passed to the icon.
    #   These are passed directly to the `helpers.icon` call. Common attributes include:
    #   - :size [String, Integer] The icon size (e.g., '24px', '1.5rem', 24). Defaults to '1.5rem' if not provided.
    #   - :class [String] Additional CSS classes. The class 'inline-block' is added by default.
    #   - :data [Hash] HTML data attributes.
    #   - In the test environment, `data-phosphor-icon` attribute is automatically added with the icon name
    #     for easier identification in tests, if an icon name is present.
    #   - Any other options supported by the `helpers.icon` method (e.g., title, etc.).
    def initialize(icon: nil, variant: :regular, **system_arguments)
      @icon_name = icon&.to_sym

      # Ensure the explicit 'variant' parameter is included in system_arguments
      # to be passed to the underlying helper.
      system_arguments[:variant] = variant

      # Set default classes, prepending 'inline-block'. User-provided classes are appended.
      system_arguments[:class] = class_names(
        'inline-block',
        system_arguments[:class]
      )

      # Set default size if not specified by the user.
      system_arguments[:size] ||= '1.5rem'

      # Add a data attribute for easier targeting in tests, only if an icon name is present.
      if Rails.env.test? && @icon_name.present?
        # Using a symbol key consistent with other options like :class, :size, :variant.
        system_arguments[:'data-phosphor-icon'] = @icon_name.to_s
      end

      @system_arguments = system_arguments
    end
  end
end
