# frozen_string_literal: true

module Groups
  # Base Controller for Groups
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation

    before_action :fixed

    layout 'groups'

    private

    def fixed
      @fixed = true
    end

    def context_crumbs
      @context_crumbs = route_to_context_crumbs(@group.route)
    end
  end
end
