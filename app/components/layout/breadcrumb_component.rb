# frozen_string_literal: true

module Layout
  # Create breadcrumbs for current route
  class BreadcrumbComponent < Component
    attr_reader :links

    def initialize(context_crumbs: nil)
      @links = validate_context_crumbs(context_crumbs)
    end

    def render?
      @links.any?
    end

    private

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
