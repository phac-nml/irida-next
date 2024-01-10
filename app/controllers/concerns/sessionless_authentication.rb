# frozen_string_literal: true

# Authentication methods for sessionless access (e.g. Graphql)
module SessionlessAuthentication
  def authenticate_sessionless_user!
    access_token = token_from_basic_authorization(request)
    username = username_from_basic_authorization(request)

    user = User.find_by(email: username)
    return unless user

    @token = user.personal_access_tokens.find_by_token(access_token) # rubocop:disable Rails/DynamicFindBy
    return unless token&.active?

    token.touch(:last_used_at) # rubocop:disable Rails/SkipsModelValidations

    sessionless_sign_in(user)
  end

  def sessionless_sign_in(user)
    sign_in(user, store: false)
  end

  def token
    @token
  end

  private

  def token_from_basic_authorization(request)
    pattern = /^Basic /i
    header = request.authorization&.strip
    token_from_basic_header(header, pattern) if header&.match(pattern)
  end

  def username_from_basic_authorization(request)
    pattern = /^Basic /i
    header = request.authorization&.strip
    username_from_basic_header(header, pattern) if header&.match(pattern)
  end

  def token_from_basic_header(header, pattern)
    encoded_header = header.gsub(pattern, '')
    decode_basic_credentials_token(encoded_header) if base64?(encoded_header)
  end

  def decode_basic_credentials_token(encoded_header)
    Base64.decode64(encoded_header).split(':', 2).last
  end

  def username_from_basic_header(header, pattern)
    encoded_header = header.gsub(pattern, '')
    decode_basic_credentials_username(encoded_header) if base64?(encoded_header)
  end

  def decode_basic_credentials_username(encoded_header)
    Base64.decode64(encoded_header).split(':', 2).first
  end

  def base64?(value)
    Base64.strict_encode64(Base64.decode64(value)) == value
  end
end
