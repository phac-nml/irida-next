# frozen_string_literal: true

# Route helper that converts Route object into context_crumbs
module RouteHelper
  def route_to_context_crumbs(route)
    crumbs = []
    return crumbs unless route

    route.path.split('/').each_with_index do |_part, index|
      crumbs << crumb_for_route(route, index)
    end
    crumbs
  end

  private

  def crumb_for_route(route, index)
    {
      name: route.name.split(' / ')[index],
      path: route.path.split('/')[0..index].join('/')
    }
  end
end
