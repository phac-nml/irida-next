# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ENTRA_TENANT_ID = 'tenant-1234'
  ENTRA_CLIENT_ID = 'client-5678'
  ENTRA_JWKS_URI = "https://login.microsoftonline.com/#{ENTRA_TENANT_ID}/discovery/v2.0/keys".freeze

  setup do
    @basic_auth = Base64.encode64("#{users(:john_doe).email}:JQ2w5maQc4zgvC8GGMEp")
    @authorization_header = "Basic #{@basic_auth}"
  end

  test 'should execute the graphql query' do
    post api_graphql_path, params: { query: '{ __schema }' },
                           headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should execute the graphql query when using variables' do
    post api_graphql_path, params: { query: '{ $query }', variables: { query: '__schema' } },
                           headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should execute the graphql query when variables empty' do
    post api_graphql_path, params: { query: '{ __schema }', variables: '' },
                           headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should execute the graphql query when variables is an empty hash' do
    post api_graphql_path, params: { query: '{ __schema }', variables: '{}' },
                           headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should report error when graphql query is invalid' do
    post api_graphql_path, params: { query: '{ does_not_exist {invalid} }' },
                           headers: { Authorization: @authorization_header }

    assert_response :success

    response_hash = response.parsed_body

    assert response_hash.key?('errors')
    assert_equal 'Field \'does_not_exist\' doesn\'t exist on type \'Query\'', response_hash['errors'][0]['message']
  end

  test 'should authenticate the graphql query as the user when using a valid entra_id bearer token' do
    user = users(:entra_doe)
    token = build_entra_id_token('scp' => 'access_as_user read_api')

    post api_graphql_path, params: { query: '{ currentUser { email } }' },
                           headers: { Authorization: "Bearer #{token}" }

    assert_response :success

    response_hash = response.parsed_body

    assert_equal user.email, response_hash['data']['currentUser']['email']
  end

  test 'should execute the graphql query anonymously when using an invalid entra_id bearer token' do
    post api_graphql_path, params: { query: '{ currentUser { email } }' },
                           headers: { Authorization: 'Bearer not-a-valid-token' }

    assert_response :success

    response_hash = response.parsed_body

    assert_nil response_hash['data']['currentUser']
  end

  test 'should execute the graphql query anonymously when no local user matches the entra_id bearer token' do
    post api_graphql_path, params: { query: '{ currentUser { email } }' },
                           headers: { Authorization: "Bearer #{build_entra_id_token('oid' => 'unknown-oid')}" }

    assert_response :success

    response_hash = response.parsed_body

    assert_nil response_hash['data']['currentUser']
  end

  test 'should execute the graphql query anonymously when the bearer token lacks access_as_user scope' do
    token = build_entra_id_token('scp' => 'api read_api')

    post api_graphql_path, params: { query: '{ currentUser { email } }' },
                           headers: { Authorization: "Bearer #{token}" }

    assert_response :success

    response_hash = response.parsed_body

    assert_nil response_hash['data']['currentUser']
  end

  test 'should allow an entra_id bearer token with the read_api scope to query the api' do
    token = build_entra_id_token('scp' => 'access_as_user read_api')

    post api_graphql_path, params: { query: '{ samples { nodes { id } } }' },
                           headers: { Authorization: "Bearer #{token}" }

    assert_response :success

    response_hash = response.parsed_body

    assert_not response_hash.key?('errors')
  end

  test 'should not allow an entra_id bearer token without any api scopes to query the api' do
    token = build_entra_id_token('scp' => 'access_as_user')

    post api_graphql_path, params: { query: '{ samples { nodes { id } } }' },
                           headers: { Authorization: "Bearer #{token}" }

    assert_response :success

    response_hash = response.parsed_body

    assert response_hash.key?('errors')
  end

  test 'should not allow an entra_id bearer token with only the read_api scope to mutate the api' do
    post api_graphql_path, params: {
      query: 'mutation { createSample(name: "x", projectPuid: "INXT_PRJ_AAAAAAAAAA") { errors } }'
    }, headers: { Authorization: "Bearer #{build_entra_id_token('scp' => 'access_as_user read_api')}" }

    assert_response :success

    response_hash = response.parsed_body

    assert response_hash.key?('errors')
  end

  private

  def build_entra_id_token(overrides = {})
    rsa_key = entra_id_signing_key
    payload = {
      'iss' => "https://login.microsoftonline.com/#{ENTRA_TENANT_ID}/v2.0",
      'aud' => ENTRA_CLIENT_ID,
      'tid' => ENTRA_TENANT_ID,
      'oid' => 'user-oid',
      'scp' => 'access_as_user',
      'exp' => 1.hour.from_now.to_i,
      'nbf' => 1.minute.ago.to_i,
      'iat' => 1.minute.ago.to_i
    }.merge(overrides)

    JWT.encode(payload, rsa_key, 'RS256', kid: entra_id_jwk.kid)
  end

  def entra_id_signing_key
    @entra_id_signing_key ||= OpenSSL::PKey::RSA.generate(2048)
  end

  def entra_id_jwk
    @entra_id_jwk ||= begin
      jwk = JWT::JWK.new(entra_id_signing_key)

      Rails.application.credentials.stubs(:entra_id).returns(
        { tenant_id: ENTRA_TENANT_ID, client_id: ENTRA_CLIENT_ID, client_secret: 'secret' }
      )
      stub_request(:get, ENTRA_JWKS_URI).to_return(
        status: 200,
        body: JWT::JWK::Set.new([jwk]).export.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      jwk
    end
  end
end
