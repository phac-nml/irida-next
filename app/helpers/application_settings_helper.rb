# frozen_string_literal: true

# Helper for ApplicationSettings
module ApplicationSettingsHelper
  delegate :allow_signup?,
           :password_authentication_enabled?,
           :require_personal_access_token_expiry?,
           to: :'Irida::CurrentSettings.current_application_settings'
end
