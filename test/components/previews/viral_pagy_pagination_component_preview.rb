# frozen_string_literal: true

class ViralPagyPaginationComponentPreview < ViewComponent::Preview
  def default
    pagy = Pagy::Offset.new(count: 100, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end

  def only_one_page
    pagy = Pagy::Offset.new(count: 1, page: 1,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end

  def many_pages
    pagy = Pagy::Offset.new(count: 1000, page: 5,
                            request: Pagy::Request.new(request: { base_url: 'localhost:3000', path: '/', params: {} }))
    render(Viral::Pagy::PaginationComponent.new(pagy))
  end
end
