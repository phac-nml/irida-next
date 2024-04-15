# frozen_string_literal: true

# Common bot actions
module BotActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { access_levels }
    before_action proc { bot_account }, only: %i[destroy]
  end

  def index
    @pagy, @bot_accounts = pagy(load_bot_accounts)
  end

  def new
    authorize! @namespace, to: :create_bot_accounts?

    @new_bot_account = User.new(first_name: @namespace.type, last_name: 'Bot')

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def create # rubocop:disable Metrics/MethodLength
    @new_bot_account = Bots::CreateService.new(current_user, @namespace, bot_params).execute

    respond_to do |format|
      format.turbo_stream do
        if @new_bot_account[:bot_user_account].persisted?
          render status: :ok, locals: {
            type: 'success',
            message: t('.success'),
            personal_access_token: @new_bot_account[:personal_access_token]
          }
        else
          render status: :unprocessable_entity,
                 locals:
                { type: 'alert',
                  message: @new_bot_account[:bot_user_account].errors.full_messages.first,
                  bot_params: }

        end
      end
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength
    Bots::DestroyService.new(@bot_account, current_user).execute

    respond_to do |format|
      format.turbo_stream do
        if @bot_account.deleted?
          render status: :ok, locals: {
            type: 'success',
            message: t('.success')
          }
        else
          render status: :unprocessable_entity,
                 locals: {
                   type: 'alert',
                   message: @bot_account.errors.full_messages.first
                 }
        end
      end
    end
  end

  private

  def bot_account
    @bot_account = @namespace.namespace_bots.find_by(id: params[:id]) || not_found
  end

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end

  def load_bot_accounts
    @namespace.bots
  end
end
