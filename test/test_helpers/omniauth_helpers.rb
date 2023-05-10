# frozen_string_literal: true

module OmniauthDeveloperHelper
  def valid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] =
      OmniAuth::AuthHash.new({ provider: 'developer', uid: '12345', info: { email: 'jeff@irida.ca', name: 'jeff' } })
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end

  def invalid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end
end

module OmniauthAzureHelper
  def valid_azure_login_setup
    OmniAuth.config.test_mode = true
    # OmniAuth.config.mock_auth[:azure_activedirectory_v2] =
    #   OmniAuth::AuthHash.new({ provider: 'developer', uid: '12345', info: { email: 'jeff@irida.ca', name: 'jeff' } })
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:azure_activedirectory_v2]
  end

  def invalid_azure_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:azure_activedirectory_v2] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:azure_activedirectory_v2]
  end
end

module OmniauthSamlHelper
  def valid_saml_login_setup
    OmniAuth.config.test_mode = true
    # OmniAuth.config.mock_auth[:saml] =
    #   OmniAuth::AuthHash.new({ provider: 'developer', uid: '12345', info: { email: 'jeff@irida.ca', name: 'jeff' } })
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
  end

  def invalid_saml_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
  end
end
