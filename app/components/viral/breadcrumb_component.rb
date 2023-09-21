# frozen_string_literal: true

module Viral
  # Create breadcrumbs for current route
  class BreadcrumbComponent < Component
    attr_reader :links

    def initialize(context_crumbs: nil)
      @links = context_crumbs.nil? ? nil : build_crumbs(context_crumbs)
    end

    def build_crumbs(context_crumbs)
      crumbs = []
      path = context_crumbs[0][:path].split('/')
      path.each_with_index do |crumb, index|
        next if index == 0 || index == path.length - 1 || crumb == '-'

        crumbs << route_to_context_crumbs(path, crumb, index)
      end
      crumbs += context_crumbs if context_crumbs.present? && validate_context_crumbs(context_crumbs)
      crumbs
    end

    # def build_crumbs(route, context_crumbs)
    #   crumbs = []
    #   route.path.split('/').each_with_index do |_part, index|
    #     crumbs << crumb_for_route(route, index)
    #   end
    #   crumbs += context_crumbs if context_crumbs.present? && validate_context_crumbs(context_crumbs)
    #   crumbs
    # end

    private

    def route_to_context_crumbs(path, crumb, index)
      namespace = Namespace.all.find_by(path: crumb)
      crumb = namespace.name if namespace

      { name: crumb, path: path[0..index].join('/')[1..-1] }
    end

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
end
