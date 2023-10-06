# frozen_string_literal: true

module Groups
  # Base Controller for Groups
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation
    layout 'groups'

    private

    def context_crumbs
      @context_crumbs = route_to_context_crumbs(@group.route)
    end
  end
end
