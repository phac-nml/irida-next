# frozen_string_literal: true

module Projects
  # Base Controller for Projects
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation

    before_action :project
    before_action :fixed

    layout 'projects'

    private

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def fixed
      @fixed = true
    end

    def context_crumbs
      @context_crumbs = route_to_context_crumbs(@project.namespace.route)
    end

    def load_samples
      Sample.where(project_id: @project.id)
    end
  end
end
