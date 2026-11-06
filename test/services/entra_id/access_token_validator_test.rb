# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

module EntraId
  class AccessTokenValidatorTest < ActiveSupport::TestCase
    TENANT_ID = 'tenant-1234'
    CLIENT_ID = 'client-5678'
    JWKS_URI = "https://login.microsoftonline.com/#{TENANT_ID}/discovery/v2.0/keys".freeze

    setup do
      @rsa_key = OpenSSL::PKey::RSA.generate(2048)
      @jwk = JWT::JWK.new(@rsa_key)

      Rails.application.credentials.stubs(:entra_id).returns(
        { tenant_id: TENANT_ID, client_id: CLIENT_ID, client_secret: 'secret' }
      )

      stub_request(:get, JWKS_URI).to_return(
        status: 200,
        body: JWT::JWK::Set.new([@jwk]).export.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    test 'validate! returns the verified claims for a valid token' do
      claims = AccessTokenValidator.new(build_token).validate!

      assert_equal 'user-oid', claims['oid']
      assert_equal TENANT_ID, claims['tid']
    end

    test 'validate! raises when entra_id is not an enabled omniauth provider' do
      Rails.configuration.auth_config.stubs(:[]).with('omniauth_providers').returns([])

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(build_token).validate!
      end
    end

    test 'validate! raises when entra_id credentials are not configured' do
      Rails.application.credentials.stubs(:entra_id).returns(nil)

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(build_token).validate!
      end
    end

    test 'validate! raises for a blank token' do
      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new('').validate!
      end
    end

    test 'validate! raises for an expired token' do
      token = build_token('exp' => 1.hour.ago.to_i)

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! raises for a token used before its nbf time' do
      token = build_token('nbf' => 1.hour.from_now.to_i)

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! raises for an unexpected audience' do
      token = build_token('aud' => 'some-other-client')

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! accepts the Application ID URI form of the audience' do
      token = build_token('aud' => "api://#{CLIENT_ID}")

      claims = AccessTokenValidator.new(token).validate!

      assert_equal 'user-oid', claims['oid']
    end

    test 'validate! accepts a configured api_audience override' do
      Rails.application.credentials.stubs(:entra_id).returns(
        { tenant_id: TENANT_ID, client_id: CLIENT_ID, client_secret: 'secret', api_audience: 'api://custom-audience' }
      )
      token = build_token('aud' => 'api://custom-audience')

      claims = AccessTokenValidator.new(token).validate!

      assert_equal 'user-oid', claims['oid']
    end

    test 'validate! raises for an unexpected issuer' do
      token = build_token('iss' => 'https://login.microsoftonline.com/other-tenant/v2.0')

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! accepts the v1 token issuer format' do
      token = build_token('iss' => "https://sts.windows.net/#{TENANT_ID}/")

      claims = AccessTokenValidator.new(token).validate!

      assert_equal 'user-oid', claims['oid']
    end

    test 'validate! raises when the tid claim does not match the configured tenant' do
      token = build_token('tid' => 'other-tenant')

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! raises for a token signed with an untrusted key' do
      token = build_token(signing_key: OpenSSL::PKey::RSA.generate(2048))

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! raises for a malformed token' do
      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new('not-a-jwt').validate!
      end
    end

    test 'validate! raises when the required access_as_user scope is missing' do
      token = build_token('scp' => 'api read_api')

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! raises when the scp claim is blank' do
      token = build_token('scp' => '')

      assert_raises(AccessTokenValidator::InvalidTokenError) do
        AccessTokenValidator.new(token).validate!
      end
    end

    test 'validate! succeeds when access_as_user is present alongside other scopes' do
      token = build_token('scp' => 'access_as_user api read_api')

      claims = AccessTokenValidator.new(token).validate!

      assert_equal 'access_as_user api read_api', claims['scp']
    end

    test '.scopes parses the space-delimited scp claim into an array' do
      assert_equal %w[access_as_user api], AccessTokenValidator.scopes({ 'scp' => 'access_as_user api' })
    end

    test '.scopes returns an empty array when the scp claim is missing' do
      assert_equal [], AccessTokenValidator.scopes({})
    end

    private

    def build_token(overrides = {})
      signing_key = overrides.delete(:signing_key) || @rsa_key
      payload = {
        'iss' => "https://login.microsoftonline.com/#{TENANT_ID}/v2.0",
        'aud' => CLIENT_ID,
        'tid' => TENANT_ID,
        'oid' => 'user-oid',
        'scp' => 'access_as_user',
        'exp' => 1.hour.from_now.to_i,
        'nbf' => 1.minute.ago.to_i,
        'iat' => 1.minute.ago.to_i
      }.merge(overrides)

      JWT.encode(payload, signing_key, 'RS256', kid: @jwk.kid)
    end
  end
end
