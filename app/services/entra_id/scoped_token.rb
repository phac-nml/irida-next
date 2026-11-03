# frozen_string_literal: true

module EntraId
  # Lightweight, non-persisted token-like object built from a verified Entra ID access token's
  # claims. This lets requests authenticated via Entra ID bearer tokens (see
  # SessionlessAuthentication) be scope-limited by the same policies that already enforce
  # PersonalAccessToken scopes (e.g. GraphqlPolicy), instead of being granted unrestricted
  # session-equivalent access.
  #
  # Only the IRIDA Next API scopes (api/read_api) present in the token's delegated permissions
  # ('scp' claim) are exposed; any other scopes granted on the token are ignored here since they
  # are not meaningful to IRIDA Next's authorization policies.
  class ScopedToken
    API_SCOPES = Irida::Auth::API_SCOPES.map(&:to_s).freeze

    attr_reader :scopes

    # @param claims [Hash] the verified claims returned by AccessTokenValidator#validate!
    def initialize(claims)
      @scopes = AccessTokenValidator.scopes(claims) & API_SCOPES
    end

    # The underlying access token has already been fully verified (signature, issuer, audience,
    # tenant, expiry and required scope) by AccessTokenValidator before this object is built, so
    # it is always considered active.
    def active?
      true
    end

    # ScopedToken is not a persisted PersonalAccessToken, so there is no last_used_ips history to
    # maintain for it. Reporting true here causes LastUsedIpConcern#update_last_used_ips to skip
    # tracking, the same way it already does for bot integration tokens.
    def integration?
      true
    end
  end
end
