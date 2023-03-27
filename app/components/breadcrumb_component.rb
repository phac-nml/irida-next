# frozen_string_literal: true

# Create breadcrumbs for current route
class BreadcrumbComponent < ViewComponent::Base
  def initialize(route:, request:)
    @links = build_crumbs(route, request)
  end

  def build_crumbs(route, request)
    crumbs = []
    route.path.split('/').each_with_index do |_part, index|
      crumbs << crumb_for_route(route, index)
    end
    if "/#{crumbs.last[:path]}" != request.path
      begin
        crumbs << crumb_for_request(request)
      rescue I18n::MissingTranslationData
        # Don't do shit
      end
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

  def crumb_for_request(request)
    {
      name: t(:"views.#{request.params[:controller]}.#{request.params[:action]}", raise: true),
      path: request.path.sub('/', '')
    }
  end
end
