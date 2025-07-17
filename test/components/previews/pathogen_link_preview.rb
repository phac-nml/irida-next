# frozen_string_literal: true

class PathogenLinkPreview < ViewComponent::Preview
  def default
    render Pathogen::Link.new(href: '#') do
      'This is a link'
    end
  end
end
