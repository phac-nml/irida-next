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
        set_flash_message(:notice, :success, kind: action_name)
      else
        # Removing extra and credentials as it can overflow some session stores
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra, :credentials)
        failure
      end
    end

    alias developer all
    alias saml all
    alias azure_activedirectory_v2 all

    def failure
      # TODO: somehow alert failed sign in?
      redirect_to root_path
    end
  end
end
