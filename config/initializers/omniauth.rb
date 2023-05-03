# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  # disable dev provider in production somehow???
  provider :developer #unless Rails.env.production?

  provider :saml,
           idp_cert_fingerprint: ENV.fetch('IDP_CERT_FINGERPRINT', nil),
           idp_sso_service_url: ENV.fetch('IDP_SSO_SERVICE_URL', nil)

  provider :azure_activedirectory_v2,
           client_id: ENV.fetch('AZURE_CLIENT_ID', nil),
           client_secret: ENV.fetch('AZURE_CLIENT_SECRET', nil)

  #  # I can't remember what this was for, from some guide??
  # configure do |config|
  #   config.path_prefix = '/users/auth'
  # end

  on_failure { |env| Users::OmniauthCallbacksController.action(:failure).call(env) }
end
