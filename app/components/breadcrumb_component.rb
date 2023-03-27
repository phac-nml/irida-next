# frozen_string_literal: true

class BreadcrumbComponent < ViewComponent::Base
  def initialize(route:, request:)
    @links = build_crumbs(route, request)
  end

  def build_crumbs(route, request)
    crumbs = []
    route.path.split('/').each_with_index do |_part, index|
      crumbs << {
        name: route.name.split(' / ')[index],
        path: route.path.split('/')[0..index].join('/')
      }
    end
    if "/#{crumbs.last[:path]}" != request.path
      begin
        crumbs << {
          name: t(:"views.#{request.params[:controller]}.#{request.params[:action]}", raise: true),
          path: request.path.sub('/', '')
        }
      rescue I18n::MissingTranslationData
        # Don't do shit
      end
    end
    crumbs
  end
end
