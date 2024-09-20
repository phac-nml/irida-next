# frozen_string_literal: true

class ViralPagyFullComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy.new(count: 100, page: 1)
    render(Viral::Pagy::FullComponent.new(pagy, item: 'items'))
  end

  def empty_state
    pagy = Pagy.new(count: 0, page: 1)
    pagy.vars[:size] = 9
    render(Viral::Pagy::FullComponent.new(pagy, item: 'items'))
  end
end
