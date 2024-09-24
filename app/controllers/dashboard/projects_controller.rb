# frozen_string_literal: true

module Dashboard
  # Dashboard Projects Controller
  class ProjectsController < ApplicationController
    before_action :current_page

    def index
      @q = authorized_projects(params).ransack(params[:q])
      set_default_sort
      respond_to do |format|
        format.html do
          @has_projects = @q.result.count.positive?
        end
        format.turbo_stream do
          @pagy, @projects = pagy(@q.result)
        end
      end
    end

    private

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end

    def authorized_projects(finder_params)
      if finder_params[:personal] == 'true'
        @personal = true
        authorized_scope(Project, type: :relation, as: :personal)
      else
        authorized_scope(Project, type: :relation)
      end
    end

    def current_page
      @current_page = t(:'general.default_sidebar.projects')
    end
  end
end
