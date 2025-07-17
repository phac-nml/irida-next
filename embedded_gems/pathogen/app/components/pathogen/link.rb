# frozen_string_literal: true

module Pathogen
  # Pathogen::Link renders a link with consistent styling across the application. Can be used with or without a tooltip.
  class Link < Pathogen::Component
    # @param href [String] The link url (required)
    # @param system_arguments [Hash] additional HTML attributes to be included in the link root element
    def initialize(href: nil, **system_arguments)
      @system_arguments = system_arguments

      @id = @system_arguments[:id] ||= self.class.generate_id

      @system_arguments[:tag] = :a
      @system_arguments[:href] = href

      @system_arguments[:aria] ||= {}
      @system_arguments[:aria][:describedby] = @id
      @system_arguments[:data] ||= {}
      @system_arguments[:data]['viral--tooltip-target'] = 'trigger'
    end

    # The tooltip that appears on mouse hover or keyboard focus over the link. (optional)
    #
    # @param tooltip_arguments [Hash] HTML attributes to be included in the tooltip root element
    renders_one :tooltip, lambda { |**tooltip_arguments|
      raise ArgumentError, 'Links with a tooltip must have a unique `id` set on the `LinkComponent`.' if @id.blank?

      Pathogen::Tooltip.new(id: @id, **tooltip_arguments)
    }

    def before_render
      raise ArgumentError, 'href is required' if @system_arguments[:href].nil?
    end
  end
end
