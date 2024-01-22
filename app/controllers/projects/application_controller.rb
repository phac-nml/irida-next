# frozen_string_literal: true

module Projects
  # Base Controller for Projects
  class ApplicationController < ApplicationController
    include BreadcrumbNavigation

    before_action :project

    layout 'projects'

    private

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def context_crumbs
      @context_crumbs = route_to_context_crumbs(@project.namespace.route)
    end

    def load_samples
      Sample.where(project_id: @project.id)
    end

    def all_metadata_fields
      @all_metadata_fields = @project.namespace.metadata_summary
    end

    def templates
      @templates = [{ id: 0, label: 'None' }, { id: 1, label: 'All' }]
    end

    def template
      @template = case params[:template]
                  when '1'
                    @project.namespace.metadata_summary.keys
                  else
                    %w[]
                  end
    end
  end
end
