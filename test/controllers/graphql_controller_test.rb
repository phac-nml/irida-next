# frozen_string_literal: true

require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should require login' do
    post api_graphql_url
    assert_redirected_to new_user_session_url
  end

  test 'should execute the graphql query' do
    sign_in users(:john_doe)

    post api_graphql_path, params: { query: '{ __schema }' }

    assert_response :success
  end

  test 'should execute the graphql query when using variables' do
    sign_in users(:john_doe)

    post api_graphql_path, params: { query: '{ $query }', variables: { query: '__schema' } }

    assert_response :success
  end

  test 'should execute the graphql query when variables empty' do
    sign_in users(:john_doe)

    post api_graphql_path, params: { query: '{ __schema }', variables: '' }

    assert_response :success
  end

  test 'should execute the graphql query when variables is an empty hash' do
    sign_in users(:john_doe)

    post api_graphql_path, params: { query: '{ __schema }', variables: '{}' }

    assert_response :success
  end

  test 'should report error when graphql query is invalid' do
    sign_in users(:john_doe)

    post api_graphql_path, params: { query: '{ does_not_exist {invalid} }' }

    assert_response :success

    response_hash = JSON.parse(response.body)

    assert response_hash.key?('errors')
    assert_equal 'Field \'does_not_exist\' doesn\'t exist on type \'Query\'', response_hash['errors'][0]['message']
  end
end
