# frozen_string_literal: true

module Pathogen
  # Pathogen::Link renders a link with consistent styling across the application. Can be used with or without a tooltip.
  class Link < Pathogen::Component
    EXTERNAL_LINK_ATTRIBUTES = {
      target: '_blank',
      rel: 'noopener noreferrer'
    }.freeze

    # @param href [String] The link url (required)
    # @param system_arguments [Hash] additional HTML attributes to be included in the link root element
    def initialize(href: nil, **system_arguments)
      @link_system_arguments = system_arguments
      @link_system_arguments[:tag] = :a
      @link_system_arguments[:href] = href
      @link_system_arguments[:class] =
        class_names(system_arguments[:class],
                    'text-grey-900 dark:text-grey-100 font-semibold underline hover:decoration-2')
    end

    # The tooltip that appears on mouse hover or keyboard focus over the link. (optional)
    #
    # @param placement [Symbol] Position of tooltip (:top, :bottom, :left, :right)
    # @param system_arguments [Hash] HTML attributes to be included in the tooltip root element
    renders_one :tooltip, lambda { |placement: :top, **system_arguments|
      @tooltip_id = Pathogen::Tooltip.generate_id
      @link_system_arguments[:aria] ||= {}
      @link_system_arguments[:aria][:describedby] = [
        @link_system_arguments[:aria][:describedby],
        @tooltip_id
      ].compact.join(' ')
      @link_system_arguments[:data] ||= {}
      @link_system_arguments[:data]['pathogen--tooltip-target'] = 'trigger'

      Pathogen::Tooltip.new(id: @tooltip_id, placement: placement, **system_arguments)
    }

    def before_render
      # Ensure tooltip slot is instantiated before rendering so that it can
      # modify @link_system_arguments with aria-describedby and data attributes
      tooltip if tooltip?

      raise ArgumentError, 'href is required' if @link_system_arguments[:href].blank?
      raise ArgumentError, "invalid href format: #{@link_system_arguments[:href]}" unless validate_href_format!

      setup_external_link_attributes if external_link?(@link_system_arguments[:href])
    end

    private

    def setup_external_link_attributes
      @link_system_arguments.merge!(EXTERNAL_LINK_ATTRIBUTES)
      @link_system_arguments[:'aria-label'] ||= t('.aria-label', content: content.strip)
    end

    def external_link?(href)
      host = URI.parse(href).host
      host.present? && host != request.host
    rescue URI::InvalidURIError
      false
    end

    def validate_href_format!
      URI.parse(@link_system_arguments[:href])
    rescue URI::InvalidURIError
      false
    end
  end
end
