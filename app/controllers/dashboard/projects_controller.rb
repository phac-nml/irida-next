# frozen_string_literal: true

module Dashboard
  # Dashboard Projects Controller
  class ProjectsController < ApplicationController
    def index
      respond_to do |format|
        format.html do
          @has_projects = Project.joins(:namespace).exists?(namespace: { parent: current_user.namespace }) ||
                          Project.joins(:namespace)
                                 .exists?(namespace: { parent: current_user.groups.self_and_descendant_ids })
        end
        format.turbo_stream do
          @pagy, @projects = pagy(load_projects(params))
        end
      end
    end

    private

    def load_projects(finder_params)
      projects = if finder_params[:personal]
                   authorized_scope(Project, type: :relation, as: :personal)
                 else
                   authorized_scope(Project, type: :relation)
                 end

      projects.order(updated_at: :desc)
    end
  end
end
