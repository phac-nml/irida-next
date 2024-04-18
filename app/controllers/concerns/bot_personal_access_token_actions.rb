# frozen_string_literal: true

# Common bot personal access token actions
module BotPersonalAccessTokenActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { bot_account }
  end

  def index
    authorize! @namespace, to: :view_bot_personal_access_tokens?

    @personal_access_tokens = @bot_account.user.personal_access_tokens
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
            message: t('.success'),
            personal_access_token: @personal_access_token
          }
        else
          render status: :unprocessable_entity,
                 locals:
                { type: 'alert',
                  message: @personal_access_token.errors.full_messages.first }

        end
      end
    end
  end

  private

  def bot_account
    @bot_account = @namespace.namespace_bots.find_by(user_id: params[:id]) || not_found
  end
end
