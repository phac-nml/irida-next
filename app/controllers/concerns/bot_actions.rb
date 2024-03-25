# frozen_string_literal: true

# Common bot actions
module BotActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { bot_account }, only: %i[destroy]
  end

  def index
    @pagy, @bot_accounts = pagy(load_bot_accounts)
  end

  def new
    authorize! @namespace.project, to: :create_bot_accounts?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    @new_bot_account = Bots::CreateService.new(current_user, @namespace.project, bot_params).execute

    if @new_bot_account.persisted?
      respond_to do |format|
        format.turbo_stream do
          @pagy, @bot_accounts = pagy(load_bot_accounts)

          render status: :ok, locals: {
            type: 'success',
            message: t('.success', bot_username: bot_params[:bot_username])
          }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals:
                 { type: 'alert',
                   message: @new_bot_account.errors.full_messages.first }
        end
      end
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength
    Bots::DestroyService.new(@bot_account, @namespace.project, current_user).execute

    if @bot_account.deleted?
      respond_to do |format|
        format.turbo_stream do
          @pagy, @bot_accounts = pagy(load_bot_accounts)

          render status: :ok, locals: {
            type: 'success',
            message: t('.success', bot_username: @bot_account.email)
          }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals: {
                   type: 'alert',
                   message: @new_bot_account.errors.full_messages.first
                 }
        end
      end
    end
  end

  private

  def bot_account
    @bot_account ||= Namespaces::UserNamespace.find_by(id: params[:id]).owner
  end

  def load_bot_accounts
    User.bots_for_puid(@namespace.project.puid)
  end
end
