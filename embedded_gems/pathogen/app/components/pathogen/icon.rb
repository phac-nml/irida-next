# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Icon component, which is responsible for
  # rendering Heroicons with various size options and caching capabilities.
  # It provides a flexible interface for using Heroicons within the Pathogen framework.
  #
  class Icon < Pathogen::Component
    erb_template <<-ERB
      <%= heroicon @icon_name, **@system_arguments %>
    ERB

    def initialize(icon: nil, **system_arguments)
      @icon_name = icon
      @system_arguments = system_arguments
    end
  end
end
