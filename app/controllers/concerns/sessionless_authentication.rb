# frozen_string_literal: true

# Authentication methods for sessionless access (e.g. Graphql)
module SessionlessAuthentication
  def authenticate_sessionless_user!
    bearer_token = bearer_token_from_authorization(request)

    if bearer_token
      authenticate_with_entra_id_bearer_token(bearer_token)
    else
      authenticate_with_personal_access_token(request)
    end
  end

  def sessionless_sign_in(user)
    sign_in(user, store: false)
  end

  def token
    @token
  end

  private

  # Personal Access Tokens are tied to a specific user and carry their own scopes
  # (api/read_api), so requests authenticated this way are limited accordingly
  # (see GraphqlPolicy).
  def authenticate_with_personal_access_token(request)
    (username, access_token) = username_and_token_from_basic_authorization(request)

    user = username && User.find_by(email: username)
    return unless user

    @token = user.personal_access_tokens.find_by_token(access_token) # rubocop:disable Rails/DynamicFindBy
    return unless @token&.active?

    # Only update token last_used_at if it is not currently being updated
    begin
      @token.with_lock('FOR UPDATE NOWAIT') do
        @token.touch(:last_used_at) # rubocop:disable Rails/SkipsModelValidations
      end
    rescue ActiveRecord::LockWaitTimeout
      Rails.logger.info "Unable to lock PersonalAccessToken (#{@token.id}) for updating last_used_at"
    end

    sessionless_sign_in(user)
  end

  # Entra ID bearer tokens let a trusted integration (e.g. BDIP) act as the signed-in Entra
  # ID user it was issued to, rather than as a shared bot account. The token's delegated
  # permissions (see AccessTokenValidator::REQUIRED_SCOPE) are required for authentication to
  # succeed at all, and its api/read_api scopes (if any) are carried into @token so existing
  # scope-aware policies (see GraphqlPolicy) apply the same restrictions as they do for
  # Personal Access Tokens.
  def authenticate_with_entra_id_bearer_token(bearer_token)
    claims = EntraId::AccessTokenValidator.new(bearer_token).validate!
    user = user_from_entra_id_claims(claims)
    return unless user

    @token = EntraId::ScopedToken.new(claims)
    sessionless_sign_in(user)
  rescue EntraId::AccessTokenValidator::InvalidTokenError => e
    Rails.logger.info "Rejected entra_id bearer token: #{e.message}"
  end

  # Mirrors OmniAuth::Strategies::EntraId#uid, which concatenates the tenant ('tid') and
  # object ('oid') identifiers to form a UID that is unique across tenants. This must stay
  # consistent with the UID assigned to users signing in interactively via the entra_id
  # OmniAuth provider (see User.from_omniauth).
  def user_from_entra_id_claims(claims)
    oid = claims['oid']
    return if oid.blank?

    User.find_by(provider: 'entra_id', uid: "#{claims['tid']}#{oid}")
  end

  def bearer_token_from_authorization(request)
    header = request.authorization&.strip

    return unless header&.match?(/^Bearer /i)

    header.sub(/^Bearer /i, '')
  end

  def username_and_token_from_basic_authorization(request)
    pattern = /^Basic /i
    header = request.authorization&.strip

    return unless header&.match(pattern)

    encoded_header = header.gsub(pattern, '')
    Base64.decode64(encoded_header).split(':', 2) if base64?(encoded_header)
  end

  def base64?(value)
    Base64.strict_encode64(Base64.decode64(value)) == value
  end
end
