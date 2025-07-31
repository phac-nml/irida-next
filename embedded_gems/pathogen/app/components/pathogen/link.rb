# frozen_string_literal: true

module Pathogen
  # Pathogen::Link renders a link with consistent styling across the application. Can be used with or without a tooltip.
  class Link < Pathogen::Component
    # @param href [String] The link url (required)
    # @param system_arguments [Hash] additional HTML attributes to be included in the link root element
    def initialize(href: nil, **system_arguments)
      @link_system_arguments = system_arguments
      @link_system_arguments[:tag] = :a
      @link_system_arguments[:href] = href
      @link_system_arguments[:class] =
        class_names(system_arguments[:class], 'text-grey-900 dark:text-grey-100 font-semibold hover:underline')

      @tooltip_id = Pathogen::Tooltip.generate_id
      @tooltip_system_arguments = {}
      @tooltip_system_arguments[:aria] = system_arguments[:aria] || {}
      @tooltip_system_arguments[:aria][:describedby] = @tooltip_id
      @tooltip_system_arguments[:data] = system_arguments[:data] || {}
      @tooltip_system_arguments[:data]['pathogen--tooltip-target'] = 'trigger'
    end

    # The tooltip that appears on mouse hover or keyboard focus over the link. (optional)
    #
    # @param system_arguments [Hash] HTML attributes to be included in the tooltip root element
    renders_one :tooltip, lambda { |**system_arguments|
      Pathogen::Tooltip.new(id: @tooltip_id, **system_arguments)
    }

    def before_render
      raise ArgumentError, 'href is required' if @link_system_arguments[:href].nil?
    end
  end
end
