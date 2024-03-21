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
      respond_to do |format|
        format.html
        format.turbo_stream do
          @pagy, @bot_accounts = pagy(load_project_bot_accounts)
        end
      end
    end

    def new
      authorize! @project, to: :create_bot_accounts?

      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    def create # rubocop:disable Metrics/MethodLength
      @new_bot_account = Bots::CreateService.new(current_user, @project, bot_params).execute

      if @new_bot_account.persisted?
        respond_to do |format|
          format.turbo_stream do
            @pagy, @bot_accounts = pagy(load_project_bot_accounts)

            render status: :ok, locals: {
              type: 'success',
              message: "Bot account '#{bot_params[:bot_username]}' was successfully added to the project"
            }
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :unprocessable_entity, locals: { type: 'alert',
                                                            message: "There was an error adding bot account #{bot_params[:bot_username]} to the project" }
          end
        end
      end
    end

    def destroy # rubocop:disable Metrics/MethodLength
      Bots::DestroyService.new(@bot_account, @project, current_user).execute

      if @bot_account.deleted?
        respond_to do |format|
          format.turbo_stream do
            @pagy, @bot_accounts = pagy(load_project_bot_accounts)

            render status: :ok, locals: {
              type: 'success',
              message: "Bot account '#{@bot_account.email}' was successfully removed"
            }
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :unprocessable_entity, locals: { type: 'alert',
                                                            message: "There was an error removing bot account #{bot_params[:bot_username]} from the project" }
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
      params.require(:bot).permit(:id, :bot_username, scopes: [])
    end

    def load_project_bot_accounts
      User.bots_for_puid(@project.puid)
    end

    protected

    def namespace
      return unless params[:project_id]

      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def bot_account
      @bot_account ||= Namespaces::UserNamespace.find_by(id: params[:id]).owner
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: 'Bot Accounts',
          path: namespace_project_bots_path
        }]
      end
    end

    def current_page
      @current_page = 'bots'
    end
  end
end
