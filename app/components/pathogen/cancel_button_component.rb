# frozen_string_literal: true

module Pathogen
  # Standard cancel button using Pathogen::Button with neutral outline styling.
  class CancelButtonComponent < ::Component
    def initialize(label: nil, href: nil, type: :button, **system_arguments)
      @label = label
      @href = href
      @type = type
      @system_arguments = system_arguments
    end

    def button_options
      options = {
        tone: :neutral,
        emphasis: :outline,
        text: button_text,
        **system_arguments
      }

      if href.present?
        options[:tag] = :a
        options[:href] = href
      else
        options[:type] = type
      end

      options
    end

    private

    attr_reader :label, :href, :type, :system_arguments

    def button_text
      label.presence || t(:'components.pathogen.cancel_button.cancel')
    end
  end
end
