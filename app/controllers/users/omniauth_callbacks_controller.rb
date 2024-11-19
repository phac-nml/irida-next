# frozen_string_literal: true

module Users
  # Handles callbacks from Omniauth providers
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-openid-providers
    protect_from_forgery with: :exception, except: %i[saml developer]

    def all
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: action_kind)
      else
        # Removing extra and credentials as it can overflow some session stores
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra, :credentials)
        failure
      end
    end

    alias developer all
    alias saml all
    alias entra_id all

    def failure
      if @user.respond_to?(:errors) && @user.errors.present? && @user.errors.full_messages.present?
        set_flash_message :alert, :failure, kind: action_kind, reason: @user.errors.full_messages.to_sentence
      end
      redirect_to new_user_session_path
    end

    private

    def action_kind
      Rails.configuration.auth_config["#{action_name}_text"] || OmniAuth::Utils.camelize(action_name)
    end
  end
end
