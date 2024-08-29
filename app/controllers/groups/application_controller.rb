# frozen_string_literal: true

module Groups
  # Base Controller for Groups
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation

    before_action :layout_fixed

    layout 'groups'

    private

    def layout_fixed
      @fixed = true
    end

    def context_crumbs
      @context_crumbs = route_to_context_crumbs(@group.route)
    end
  end
end
