# frozen_string_literal: true

# Common bot actions
module BotActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { access_levels }
    before_action proc { bot_account }, only: %i[destroy destroy_confirmation]
    before_action proc { bot_type }, only: %i[create]
    before_action proc { bot_accounts }
  end

  def index
    authorize! @namespace, to: :view_bot_accounts?

    @pagy, @bot_accounts = pagy(@bot_accounts)
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
    @new_bot_account = Bots::CreateService.new(current_user, @namespace, @bot_type, bot_params).execute

    respond_to do |format|
      format.turbo_stream do
        if @new_bot_account[:bot_user_account].persisted?
          render status: :ok, locals: {
            type: 'success',
            message: t('concerns.bot_actions.create.success'),
            personal_access_token: @new_bot_account[:personal_access_token]
          }
        else
          render status: :unprocessable_entity,
                 locals:
                { type: 'alert',
                  message: error_message(@new_bot_account[:bot_user_account]),
                  bot_params: }

        end
      end
    end
  end

  def destroy_confirmation
    authorize! @namespace, to: :destroy_bot_accounts?
    render turbo_stream: turbo_stream.update('bot_modal',
                                             partial: 'destroy_confirmation_modal',
                                             locals: {
                                               open: true,
                                               bot_account: @bot_account
                                             }), status: :ok
  end

  def destroy
    Bots::DestroyService.new(@bot_account, current_user).execute
    respond_to do |format|
      format.turbo_stream do
        if @bot_account.deleted?
          render status: :ok, locals: {
            type: 'success',
            message: t('concerns.bot_actions.destroy.success')
          }
        else
          render status: :unprocessable_entity,
                 locals: {
                   type: 'alert',
                   message: error_message(@bot_account)
                 }
        end
      end
    end
  end

  private

  def bot_account
    id = params[:bot_id] || params[:id]
    @bot_account = @namespace.namespace_bots.find_by(id:) || not_found
  end

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end

  def bot_accounts
    @bot_accounts = @namespace.namespace_bots.includes(:user)
  end
end
