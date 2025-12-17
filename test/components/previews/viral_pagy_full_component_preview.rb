# frozen_string_literal: true

class ViralPagyFullComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy::Offset.new(count: 100, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    render(Viral::Pagy::FullComponent.new(pagy, item: 'items'))
  end

  def empty_state
    pagy = Pagy::Offset.new(count: 0, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    render(Viral::Pagy::FullComponent.new(pagy, item: 'items'))
  end
end
