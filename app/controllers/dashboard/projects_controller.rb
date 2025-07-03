# frozen_string_literal: true

module Dashboard
  # Dashboard Projects Controller
  class ProjectsController < ApplicationController
    before_action :current_page
    before_action :page_title

    def index
      all_projects = authorized_projects(params)
      @has_projects = all_projects.count.positive?
      @q = all_projects.ransack(params[:q])
      set_default_sort
      @pagy, @projects = pagy(@q.result)

      respond_to do |format|
        format.html
      end
    end

    private

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end

    def authorized_projects(finder_params)
      if finder_params[:personal] == 'true'
        authorized_scope(Project, type: :relation, as: :personal)
      else
        authorized_scope(Project, type: :relation)
      end
    end

    def current_page
      @current_page = t(:'general.default_sidebar.projects')
    end

    def page_title
      @title = t(:'general.default_sidebar.projects')
    end
  end
end
