# frozen_string_literal: true

# AuthHelper provides helper methods related to authentication, such as checking if omniauth providers are configured.
module AuthHelper
  def omniauth_enabled?
    !User.omniauth_providers.empty?
  end

  def enabled_button_based_providers
    User.omniauth_providers
  end

  def button_based_providers_enabled?
    enabled_button_based_providers.any?
  end

  # Keeps a non-default locale on links between the auth pages.
  def auth_locale_params
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end

  # Flash messages for the auth layout, as [type, message] pairs.
  #
  # Being asked to sign in is not an error. It reads as information after a deep link,
  # and says nothing at all to someone who simply opened the application.
  def auth_flash_messages
    flash.filter_map do |key, message|
      next unless message.is_a?(String)

      sign_in_prompt = message == t('devise.failure.unauthenticated')
      next if sign_in_prompt && session['user_return_to'] == root_path

      [key.to_s == 'alert' && !sign_in_prompt ? :danger : :info, message]
    end
  end
end
