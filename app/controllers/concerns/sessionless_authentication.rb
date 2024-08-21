# frozen_string_literal: true

# Authentication methods for sessionless access (e.g. Graphql)
module SessionlessAuthentication
  def authenticate_sessionless_user!
    (username, access_token) = username_and_token_from_basic_authorization(request)

    user = username && User.find_by(email: username)
    return unless user

    @token = user.personal_access_tokens.active.find_by_token(access_token) # rubocop:disable Rails/DynamicFindBy

    return unless @token

    @token.touch(:last_used_at) # rubocop:disable Rails/SkipsModelValidations

    sessionless_sign_in(user)
  end

  def sessionless_sign_in(user)
    sign_in(user, store: false)
  end

  def token
    @token
  end

  private

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
