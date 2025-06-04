# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Icon component, which is responsible for
  # rendering Heroicons with various size options and caching capabilities.
  # It provides a flexible interface for using Heroicons within the Pathogen framework.
  #
  class Icon < Pathogen::Component
    erb_template <<-ERB
      <%= icon @icon_name, class: @classes %>
    ERB

    def initialize(icon: nil, classes: nil)
      @icon_name = icon
      @classes = classes
    end
  end
end
