# frozen_string_literal: true

# Common bot personal access token actions
module BotPersonalAccessTokenActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { bot_account }
    before_action proc { personal_access_tokens }, only: %i[index revoke]
    before_action proc { personal_access_token }, only: %i[revoke revoke_confirmation]
    before_action proc { bot_accounts }
  end

  def index
    authorize! @namespace, to: :view_bot_personal_access_tokens?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def new
    authorize! @namespace, to: :generate_bot_personal_access_token?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def create # rubocop:disable Metrics/MethodLength
    @personal_access_token = PersonalAccessTokens::CreateService.new(current_user, bot_personal_access_token_params,
                                                                     @namespace, @bot_account.user).execute
    respond_to do |format|
      format.turbo_stream do
        if @personal_access_token.persisted?
          render status: :ok, locals: {
            type: 'success',
            message: t('concerns.bot_personal_access_token_actions.create.success'),
            personal_access_token: @personal_access_token
          }
        else
          render status: :unprocessable_entity,
                 locals:
                { type: 'alert',
                  message: error_message(@personal_access_token) }

        end
      end
    end
  end

  def revoke_confirmation
    authorize! @namespace, to: :revoke_bot_personal_access_token?
    render turbo_stream: turbo_stream.update('token_dialog',
                                             partial: 'revoke_confirmation_modal',
                                             locals: {
                                               open: true,
                                               personal_access_token: @personal_access_token,
                                               bot_account: @bot_account
                                             }), status: :ok
  end

  def revoke
    respond_to do |format|
      format.turbo_stream do
        if @personal_access_token.revoke!
          render status: :ok, locals: {
            personal_access_token: @personal_access_token, type: 'success',
            message: t('concerns.bot_personal_access_token_actions.revoke.success',
                       pat_name: @personal_access_token.name)
          }
        else
          render status: :unprocessable_entity, locals: { type: 'alert',
                                                          message: error_message(@personal_access_token) }
        end
      end
    end
  end

  private

  def bot_account
    @bot_account = @namespace.namespace_bots.find_by(id: params[:bot_id]) || not_found
  end

  def personal_access_tokens
    @personal_access_tokens = @bot_account.user.personal_access_tokens.active
  end

  def personal_access_token
    @personal_access_token = @bot_account.user.personal_access_tokens.find_by(id: params[:id]) || not_found
  end

  def bot_accounts
    @bot_accounts = @namespace.namespace_bots.includes(:user)
  end
end
