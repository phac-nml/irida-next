# frozen_string_literal: true

# Create breadcrumbs for current route
class BreadcrumbComponent < Component
  def initialize(route:, context_crumbs: nil)
    @links = build_crumbs(route, context_crumbs)
  end

  def build_crumbs(route, context_crumbs)
    crumbs = []
    route.path.split('/').each_with_index do |_part, index|
      crumbs << crumb_for_route(route, index)
    end
    crumbs += context_crumbs if context_crumbs.present? && validate_context_crumbs(context_crumbs)
    crumbs
  end

  private

  def crumb_for_route(route, index)
    {
      name: route.name.split(' / ')[index],
      path: route.path.split('/')[0..index].join('/')
    }
  end

  def validate_context_crumbs(context_crumbs)
    raise ArgumentError, 'Context crumbs must be an array' unless context_crumbs.is_a?(Array)

    context_crumbs.each do |crumb|
      raise ArgumentError, 'Context crumbs must be a hash' unless crumb.is_a?(Hash)
      raise ArgumentError, 'Context crumbs must have a name' unless crumb.key?(:name)
      raise ArgumentError, 'Context crumbs must have a path' unless crumb.key?(:path)
    end
  end
end
