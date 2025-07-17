# frozen_string_literal: true

module Pathogen
  # Pathogen::Link renders a link with consistent styling across the application. Can be used with or without a tooltip.
  class Link < Pathogen::Component

    # @param href [String] The link url (required)
    # @param system_arguments [Hash] Additional HTML/system arguments
    def initialize(href: nil, **system_arguments)
      @system_arguments = system_arguments

      @id = @system_arguments[:id]

      @system_arguments[:tag] = :a
      @system_arguments[:href] = href
    end

    def before_render
      raise ArgumentError, 'href is required' if @system_arguments[:href].nil?
    end
  end
end
