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
end
