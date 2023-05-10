# frozen_string_literal: true

module OmniauthDeveloperHelper
  def valid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] =
      OmniAuth::AuthHash.new({ provider: 'developer', uid: '12345', info: { email: 'jeff@irida.ca' } })
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end

  def invalid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end
end
