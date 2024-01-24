# frozen_string_literal: true

module Projects
  # Controller actions for project history
  class HistoryController < Projects::ApplicationController
    before_action :current_page

    def index
      authorize! @project, to: :history?

      @project_with_log_data = @project.namespace.log_data_without_changes
    end

    def new
      authorize! @project, to: :history?

      @project_with_log_data = @project.namespace.log_data_with_changes(params[:version])
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    protected

    def context_crumbs
      super
      case action_name
      when 'index', 'new'
        @context_crumbs += [{
          name: I18n.t('projects.members.index.title'),
          path: namespace_project_members_path
        }]
      end
    end

    def current_page
      @current_page = 'history'
    end
  end
end
