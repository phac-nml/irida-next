# frozen_string_literal: true

module Pathogen
  class IconPreview < ViewComponent::Preview
    # @!group Icons
    # @label Phosphor Icons
    # @description Display all available Phosphor icons in a grid layout
    def phosphor_icons; end

    # @label Heroicons
    # @description Display all available Heroicons in a grid layout
    def heroicons; end

    # @label Named Icons
    # @description Display all available Named icons in a grid layout
    def named_icons; end

    # @label Special Icons
    # @description Display all special/semantic icons in a grid layout
    def special_icons; end

    # @!endgroup
  end
end
