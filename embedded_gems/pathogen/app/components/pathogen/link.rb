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
    end

    # The tooltip that appears on mouse hover or keyboard focus over the link. (optional)
    #
    # @param system_arguments [Hash] HTML attributes to be included in the tooltip root element
    renders_one :tooltip, lambda { |**system_arguments|
      @tooltip_id = Pathogen::Tooltip.generate_id
      @link_system_arguments[:aria] ||= {}
      @link_system_arguments[:aria][:describedby] = @tooltip_id
      @link_system_arguments[:data] ||= {}
      @link_system_arguments[:data]['pathogen--tooltip-target'] = 'trigger'

      Pathogen::Tooltip.new(id: @tooltip_id, **system_arguments)
    }

    def before_render
      raise ArgumentError, 'href is required' if @link_system_arguments[:href].nil?

      validate_href_format! if @link_system_arguments[:href].present?
    end

    private

    def validate_href_format!
      URI.parse(@link_system_arguments[:href])
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid href format: #{@link_system_arguments[:href]}"
    end
  end
end
