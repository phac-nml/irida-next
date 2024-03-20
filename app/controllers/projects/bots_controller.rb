# frozen_string_literal: true

module Projects
  # Controller actions for Bots
  class BotsController < Projects::ApplicationController
    include BreadcrumbNavigation
    layout :resolve_layout
    before_action :namespace, only: %i[index new create destroy]
    before_action :bot_account, only: %i[destroy]

    before_action :current_page

    def index
      @bot_accounts = User.bots_for_puid(@project.puid)
    end

    def new
      authorize! @project, to: :create_bot_accounts?

      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    def create
      @new_bot_account = Bots::CreateService.new(current_user, @project, bot_params).execute

      if @new_bot_account.persisted?
        respond_to do |format|
          format.turbo_stream do
            render status: :ok
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      Bots::DestroyService.new(@bot_account, @project, current_user).execute

      if @bot_account.deleted?
        respond_to do |format|
          format.turbo_stream do
            render status: :ok
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :unprocessable_entity
          end
        end
      end
    end

    def resolve_layout
      case action_name
      when 'new', 'create'
        'application'
      else
        'projects'
      end
    end

    private

    def bot_params
      params.require(:bot).permit(:bot_username, scopes: [])
    end

    protected

    def namespace
      return unless params[:project_id]

      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def current_page
      @current_page = case action_name
                      when 'show'
                        'details'
                      when 'new'
                        'projects'
                      when 'history'
                        'history'
                      when 'bots'
                        'bots'
                      else
                        'settings'
                      end
    end

    def bot_account
      @bot_account ||= Namespaces::UserNamespace.find_by(id: params[:id]).owner
    end
  end
end
