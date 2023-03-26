# frozen_string_literal: true

class BreadcrumbComponent < ViewComponent::Base
  def initialize(route:)
    @links = build_crumbs(route)
  end

  def build_crumbs(route)
    crumbs = []
    route.path.split('/').each_with_index do |_part, index|
      crumbs << {
        name: route.name.split(' / ')[index],
        path: route.path.split('/')[0..index].join('/')
      }
    end
    crumbs
  end
end
