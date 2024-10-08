# frozen_string_literal: true

# Authentication methods for sessionless access (e.g. Graphql)
module SessionlessAuthentication
  def authenticate_sessionless_user!
    user = find_user_for_graphql_api_request

    return unless user

    sessionless_sign_in(user)
  end

  def sessionless_sign_in(user)
    sign_in(user, store: false)
  end

  def token
    @token
  end

  private

  def find_user_for_graphql_api_request
    find_user_from_oauth_token || find_user_from_personal_access_token
  end

  def find_user_from_oauth_token
    token = Doorkeeper::OAuth::Token.from_request(request, *Doorkeeper.configuration.access_token_methods)
    return unless token

    # Expiration, revocation and scopes are verified in `validate_access_token!`
    oauth_token = Doorkeeper.config.access_token_model.by_token(token)
    raise UnauthorizedError unless oauth_token

    oauth_token.revoke_previous_refresh_token!
    oauth_token.resource_owner
  end

  def find_user_from_personal_access_token
    (username, access_token) = username_and_token_from_basic_authorization(request)

    user = username && User.find_by(email: username)
    return unless user

    @token = user.personal_access_tokens.find_by_token(access_token) # rubocop:disable Rails/DynamicFindBy
    return unless @token&.active?

    @token.touch(:last_used_at) # rubocop:disable Rails/SkipsModelValidations
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
