# frozen_string_literal: true

module Users
  # Handles callbacks from Omniauth providers
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
    skip_before_action :verify_authenticity_token

    def developer
      Rails.logger.debug('Omniauth callback developer')
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: 'DEVELOPER') if is_navigational_format?
      else
        # Removing extra as it can overflow some session stores
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra)
        redirect_to new_user_registration_url
      end
    end

    def saml
      Rails.logger.debug('Omniauth callback saml')
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: 'SAML') if is_navigational_format?
      else
        # Removing extra as it can overflow some session stores
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra)
        redirect_to new_user_registration_url
      end
    end

    def azure_activedirectory_v2
      Rails.logger.debug('omniauth callback azure_activedirectory_v2')
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: 'Azure') if is_navigational_format?
      else
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra)
        redirect_to new_user_registration_url
      end
    end
  end
end
