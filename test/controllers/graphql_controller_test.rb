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

  test 'should execute the graphql query over get' do
    get api_graphql_path, params: { query: '{ __schema }' },
                          headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should reject a graphql mutation submitted over get' do
    mutation = 'mutation { createGroup(input: { name: "Test", path: "test" }) { group { id } } }'

    get api_graphql_path, params: { query: mutation },
                          headers: { Authorization: @authorization_header }

    assert_response :method_not_allowed
    assert_equal 'POST', response.headers['Allow']

    response_hash = response.parsed_body

    assert response_hash.key?('errors')
    assert_equal 'GraphQL mutations must be submitted via HTTP POST.', response_hash['errors'][0]['message']
  end

  test 'should not reject a graphql mutation submitted over post' do
    mutation = 'mutation { createGroup(input: { name: "Test", path: "test" }) { group { id } } }'

    post api_graphql_path, params: { query: mutation },
                           headers: { Authorization: @authorization_header }

    assert_response :success
  end

  test 'should reject a document containing a query and a mutation submitted over get ' \
       'when operationName selects the mutation' do
    document = <<~GRAPHQL
      query GetSchema { __schema { queryType { name } } }
      mutation CreateGroup { createGroup(input: { name: "Test", path: "test" }) { group { id } } }
    GRAPHQL

    get api_graphql_path, params: { query: document, operationName: 'CreateGroup' },
                          headers: { Authorization: @authorization_header }

    assert_response :method_not_allowed

    response_hash = response.parsed_body

    assert response_hash.key?('errors')
    assert_equal 'GraphQL mutations must be submitted via HTTP POST.', response_hash['errors'][0]['message']
  end

  test 'should execute a document containing a query and a mutation submitted over get ' \
       'when operationName selects the query' do
    document = <<~GRAPHQL
      query GetSchema { __schema { queryType { name } } }
      mutation CreateGroup { createGroup(input: { name: "Test", path: "test" }) { group { id } } }
    GRAPHQL

    get api_graphql_path, params: { query: document, operationName: 'GetSchema' },
                          headers: { Authorization: @authorization_header }

    assert_response :success
  end
end
