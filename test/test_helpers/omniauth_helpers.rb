# frozen_string_literal: true

module OmniauthDeveloperHelper
  RESPONSE = {
    provider: 'developer',
    uid: '12345',
    info: {
      email: 'jeff.thiessen@irida.ca',
      name: 'jeff',
      first_name: 'Jeff',
      last_name: 'Thiessen'
    }
  }.freeze

  def valid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new(RESPONSE)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end

  def invalid_developer_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:developer]
  end
end

module OmniauthAzureHelper
  RESPONSE = {
    provider: 'entra_id',
    uid: '12345678-90-abcd-ef12-34567890abcd',
    info: {
      email: 'jeff@irida.ca',
      name: 'Jeff Thiessen',
      nickname: 'jthiessen@internal.domain',
      first_name: 'Jeff',
      last_name: 'Thiessen'
    },
    credentials: {
      token: 'somelongbinary',
      expires_at: 1_683_822_607,
      expires: true
    },
    extra: {
      these: 'fields',
      not: 'relavent'
    }
  }.freeze

  def valid_azure_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:entra_id] = OmniAuth::AuthHash.new(RESPONSE)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:entra_id]
  end

  def invalid_azure_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:entra_id] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:entra_id]
  end
end

module OmniauthSamlHelper
  RESPONSE = {
    provider: 'saml',
    uid: 'jthiessen@internal.domain',
    info: {
      email: 'jeff@irida.ca',
      name: 'jthiessen@internal.domain',
      first_name: 'Jeff',
      last_name: 'Thiessen'
    },
    credentials: {},
    extra: {
      these: 'fields',
      not: 'relavent'
    }
  }.freeze

  def valid_saml_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(RESPONSE)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
  end

  def invalid_saml_login_setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = :invalid_credentials
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
  end
end
