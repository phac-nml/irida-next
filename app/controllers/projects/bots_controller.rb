# frozen_string_literal: true

module Projects
  # Controller actions for Bots
  class BotsController < Projects::ApplicationController
    include BreadcrumbNavigation
    include BotActions

    respond_to :turbo_stream
    before_action :current_page

    private

    def bot_params
      params.require(:bot).permit(:id, :token_name, :access_level, :expires_at, scopes: [])
    end

    protected

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: t('projects.bots.index.title'),
          path: namespace_project_bots_path
        }]
      end
    end

    def current_page
      @current_page = t(:'projects.sidebar.bot_accounts')
    end

    def bot_type
      @bot_type = User.user_types[:project_bot]
    end
  end
end
