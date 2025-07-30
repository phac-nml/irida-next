# frozen_string_literal: true

class PathogenLinkPreview < ViewComponent::Preview
  include Pathogen::ViewHelper

  def default
    pathogen_link(href: '#') do
      'This is a link'
    end
  end

  # @label With Tooltip
  def tooltip
    pathogen_link(href: '#') do |component|
      component.with_tooltip(text: 'Tooltip text')
      'This is a link with tooltip'
    end
  end
end
