# frozen_string_literal: true

class ViralPagyLimitComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy.new(count: 100, page: 1)
    item = 'item'

    render(Viral::Pagy::LimitComponent.new(pagy, item:))
  end

  def with_one_item
    pagy = Pagy.new(count: 1, page: 1)
    item = 'item'

    render(Viral::Pagy::LimitComponent.new(pagy, item:))
  end
end
