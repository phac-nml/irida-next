# frozen_string_literal: true

module Dashboard
  # Dashboard Projects Controller
  class ProjectsController < ApplicationController
    def index # rubocop:disable Metric/AbcSize
      @q = Project.ransack(params[:q])
      set_default_sort
      respond_to do |format|
        format.html do
          @has_projects = Project.joins(:namespace).exists?(namespace: { parent: current_user.namespace }) ||
                          Project.joins(:namespace)
                                 .exists?(namespace: { parent: current_user.groups.self_and_descendant_ids })
        end
        format.turbo_stream do
          @pagy, @projects = pagy(@q.result.where(id: load_projects(params).select(:id))
                                           .include_route.order(updated_at: :desc))
        end
      end
    end

    private

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end

    def load_projects(finder_params)
      if finder_params[:personal]
        authorized_scope(Project, type: :relation, as: :personal)
      else
        authorized_scope(Project, type: :relation)
      end
    end
  end
end
