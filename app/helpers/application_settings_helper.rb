# frozen_string_literal: true

# Helper for ApplicationSettings
module ApplicationSettingsHelper
  delegate :allow_signup?,
           :password_authentication_enabled?,
           :user_opt_in_features,
           to: :'Irida::CurrentSettings.current_application_settings'
end
