# frozen_string_literal: true

class ViralPagyLimitComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy::Offset.new(count: 100, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    item = 'item'

    render(Viral::Pagy::LimitComponent.new(pagy, item:))
  end

  def with_one_item
    pagy = Pagy::Offset.new(count: 1, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    item = 'item'

    render(Viral::Pagy::LimitComponent.new(pagy, item:))
  end
end
