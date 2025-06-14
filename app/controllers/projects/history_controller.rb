# frozen_string_literal: true

module Projects
  # Controller actions for project history
  class HistoryController < Projects::ApplicationController
    include HistoryActions

    before_action :current_page
    before_action :page_title

    private

    # The model the log data is attached to
    def set_model
      @model = @project.namespace
    end

    # The record to authorize the user against
    def set_authorization_object
      @authorize_object = @project
    end

    protected

    def context_crumbs
      super
      case action_name
      when 'index', 'new'
        @context_crumbs += [{
          name: I18n.t('projects.history.index.title'),
          path: namespace_project_history_path
        }]
      end
    end

    def current_page
      @current_page = t(:'projects.sidebar.history')
    end

    def page_title
      @title = [t(:'projects.sidebar.history'), t(:'projects.edit.title'), @project.full_name].join(' · ')
    end
  end
end
