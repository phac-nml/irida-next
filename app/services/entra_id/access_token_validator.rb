# frozen_string_literal: true

module EntraId
  # Validates Microsoft Entra ID (formerly Azure AD) OAuth2 access tokens so the GraphQL
  # API can authenticate requests made by trusted integrations (e.g. BDIP) acting on behalf
  # of a signed-in user, instead of relying solely on a shared bot/service account.
  #
  # The bearer token is expected to have been issued to the integration via Entra ID's
  # On-Behalf-Of flow, scoped to this application's app registration, and presented as an
  # `Authorization: Bearer <token>` header.
  class AccessTokenValidator
    # Raised for any failure while validating a bearer token. The message is safe to log,
    # but should not be surfaced verbatim to API clients.
    class InvalidTokenError < StandardError; end

    ALGORITHM = 'RS256'
    JWKS_CACHE_EXPIRY = 1.hour
    JWKS_REFRESH_THROTTLE = 5.minutes

    # Delegated permission that must be present (in the 'scp' claim) for a bearer token to be
    # accepted at all, regardless of which IRIDA Next API scopes (api/read_api) it also grants.
    # This is the scope exposed on this application's Entra app registration and consented to
    # by the integration performing the On-Behalf-Of exchange.
    REQUIRED_SCOPE = 'access_as_user'

    class << self
      # Whether bearer-token authentication via Entra ID is configured and available.
      def enabled?
        Rails.configuration.auth_config['omniauth_providers'].to_a.include?('entra_id') && credentials.present?
      end

      def credentials
        Rails.application.credentials.entra_id
      end

      # Parses the space-delimited delegated permissions from a verified token's 'scp' claim.
      #
      # @return [Array<String>]
      def scopes(payload)
        payload['scp'].to_s.split
      end
    end

    def initialize(token)
      @token = token
    end

    # Decodes and verifies the access token's signature, issuer, audience, tenant, expiry and
    # required scope.
    #
    # @return [Hash] the verified claims (including at least 'oid', 'tid' and 'scp')
    # @raise [InvalidTokenError] if the token is missing, malformed, expired, not configured, or
    #   missing the REQUIRED_SCOPE
    def validate!
      raise InvalidTokenError, 'entra_id bearer token authentication is not configured' unless self.class.enabled?
      raise InvalidTokenError, 'entra_id access token is blank' if token.blank?

      payload, = JWT.decode(token, nil, true, decode_options)
      verify_tenant!(payload)
      verify_required_scope!(payload)
      payload
    rescue JWT::DecodeError, JWT::JWKError => e
      raise InvalidTokenError, "invalid entra_id access token: #{e.message}"
    end

    private

    attr_reader :token

    def tenant_id
      self.class.credentials[:tenant_id]
    end

    # The audience is normally this application's own Entra client_id (or its Application ID
    # URI form), since the integration exchanges the signed-in user's token for one scoped to
    # this application's exposed API via the On-Behalf-Of flow. An explicit `api_audience`
    # credential may be set to override this, e.g. when a separate app registration is used to
    # expose the API.
    def audiences
      configured_audience = self.class.credentials[:api_audience]
      return Array(configured_audience) if configured_audience.present?

      client_id = self.class.credentials[:client_id]
      [client_id, "api://#{client_id}"]
    end

    def issuers
      [
        "https://login.microsoftonline.com/#{tenant_id}/v2.0",
        "https://sts.windows.net/#{tenant_id}/"
      ]
    end

    def decode_options
      {
        algorithms: [ALGORITHM],
        verify_iss: true,
        iss: issuers,
        verify_aud: true,
        aud: audiences,
        verify_expiration: true,
        verify_not_before: true,
        jwks: jwks_loader
      }
    end

    # Defense in depth: in addition to the issuer check, ensure the token's tenant (if present)
    # matches the configured tenant, since a single app registration could in theory accept
    # tokens from unrelated tenants depending on how it is configured in Entra.
    def verify_tenant!(payload)
      return if payload['tid'].blank? || payload['tid'] == tenant_id

      raise InvalidTokenError, 'entra_id access token was issued for an unexpected tenant'
    end

    # Rejects tokens that were not issued with explicit consent to act as the user against this
    # application (e.g. tokens scoped to some other API that happen to pass signature/audience
    # checks because they share the same app registration).
    def verify_required_scope!(payload)
      return if self.class.scopes(payload).include?(REQUIRED_SCOPE)

      raise InvalidTokenError, "entra_id access token is missing required scope '#{REQUIRED_SCOPE}'"
    end

    def jwks_loader
      lambda do |jwks_options|
        invalidate_jwks_cache! if jwks_options[:kid_not_found]

        JWT::JWK::Set.new(fetch_jwks)
      end
    end

    # Throttles cache invalidation so that a token presenting an unknown `kid` cannot be used to
    # repeatedly force network requests to the JWKS endpoint.
    def invalidate_jwks_cache!
      return unless Rails.cache.write(jwks_refresh_guard_key, true, expires_in: JWKS_REFRESH_THROTTLE,
                                                                    unless_exist: true)

      Rails.cache.delete(jwks_cache_key)
    end

    def fetch_jwks
      Rails.cache.fetch(jwks_cache_key, expires_in: JWKS_CACHE_EXPIRY) do
        response = Faraday.get(jwks_uri)

        unless response.success?
          raise InvalidTokenError, "unable to retrieve entra_id signing keys (#{response.status})"
        end

        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def jwks_uri
      "https://login.microsoftonline.com/#{tenant_id}/discovery/v2.0/keys"
    end

    def jwks_cache_key
      "entra_id/jwks/#{tenant_id}"
    end

    def jwks_refresh_guard_key
      "#{jwks_cache_key}/refresh_guard"
    end
  end
end
