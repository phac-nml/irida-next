# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Icon component, which is responsible for
  # rendering Phosphor icons with various size options and caching capabilities.
  # It provides a flexible interface for using Phosphor icons within the Pathogen framework.
  #
  class Icon < Pathogen::Component
    erb_template <<-ERB
      <% if @icon_name.present? %>
        <%= helpers.icon(@icon_name, **@system_arguments) %>
      <% end %>
    ERB

    # @param icon [Symbol, String] The name of the Phosphor icon to render
    # @param variant [Symbol] The variant of the icon (default: :regular, options: :regular, :thin, :light, :bold, :fill, :duotone)
    # @param size [String, Integer] The size of the icon (default: 1.5rem)
    # @param class [String] Additional CSS classes to apply to the icon
    # @param data [Hash] HTML data attributes
    # @param system_arguments [Hash] Additional HTML attributes to be passed to the icon
    def initialize(icon: nil, variant: :regular, **system_arguments)
      @icon_name = icon&.to_sym
      @variant = variant
      
      # Set default classes if none provided
      system_arguments[:class] = class_names(
        'inline-block',
        system_arguments[:class]
      )
      
      # Set default size if not specified
      system_arguments[:size] ||= '1.5rem'
      
      @system_arguments = system_arguments
    end
  end
end
