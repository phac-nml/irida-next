# frozen_string_literal: true

require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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
end
