# frozen_string_literal: true

module Projects
  # Base Controller for Projects
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation

    before_action :project
    before_action :layout_fixed

    layout 'projects'

    private

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Project.includes({ namespace: [{ parent: :route }, :route] })
                          .find_by(namespace_id: Namespaces::ProjectNamespace.find_by_full_path(path).id) # rubocop:disable Rails/DynamicFindBy
    end

    def layout_fixed
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
