# frozen_string_literal: true

class ViralPagyPaginationComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy.new(count: 100, page: 1)
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end

  def only_one_page
    pagy = Pagy.new(count: 1, page: 1)
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end

  def many_pages
    pagy = Pagy.new(count: 1000, page: 5)
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end
end
