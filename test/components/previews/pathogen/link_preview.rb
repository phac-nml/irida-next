# frozen_string_literal: true

module Pathogen
  class LinkPreview < ViewComponent::Preview
    include Pathogen::ViewHelper

    def default
      render Pathogen::Link.new(href: '#') do
        'This is a link'
      end
    end

    def external_link
      render Pathogen::Link.new(href: 'http://google.com') do
        'This is an external link'
      end
    end

    # @label With Tooltip
    def tooltip
      render Pathogen::Link.new(href: '#') do |component|
        component.with_tooltip(text: 'Tooltip text')
        'This is a link with tooltip'
      end
    end
  end
end
