# frozen_string_literal: true

class PathogenLinkPreview < ViewComponent::Preview
  def default
    render Pathogen::Link.new(href: '#') do
      'This is a link'
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
