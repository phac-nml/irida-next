# frozen_string_literal: true

require 'test_helper'

class NamespaceQueryTest < ActiveSupport::TestCase
  NAMESPACE_QUERY = <<~GRAPHQL
    query($namespacePath: ID!) {
      namespace(fullPath: $namespacePath) {
        name
        path
        description
        id
        fullName
        fullPath
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'namespace query should work for Group' do
    namespace = groups(:group_one)

    result = IridaSchema.execute(NAMESPACE_QUERY, context: { current_user: @user },
                                                  variables: { namespacePath: namespace.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['namespace']

    assert_not_empty data, 'namespace type should work'
    assert_equal namespace.name, data['name']

    assert_equal namespace.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'namespace query should work for Group with uploader access level' do
    user = users(:user_group_bot_account0)
    token = personal_access_tokens(:user_group_bot_account0_valid_pat)
    namespace = groups(:group_one)

    result = IridaSchema.execute(NAMESPACE_QUERY, context: { current_user: user, token: },
                                                  variables: { namespacePath: namespace.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['namespace']

    assert_not_empty data, 'namespace type should work'
    assert_equal namespace.name, data['name']

    assert_equal namespace.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'namespace query should work for Namespaces::UserNamespace' do
    namespace = namespaces_user_namespaces(:john_doe_namespace)

    result = IridaSchema.execute(NAMESPACE_QUERY, context: { current_user: @user },
                                                  variables: { namespacePath: namespace.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['namespace']

    assert_not_empty data, 'namespace type should work'
    assert_equal namespace.name, data['name']

    assert_equal namespace.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'namespace query should not work for Namespaces::ProjectNamespace' do
    namespace = namespaces_project_namespaces(:project1_namespace)

    result = IridaSchema.execute(NAMESPACE_QUERY, context: { current_user: @user },
                                                  variables: { namespacePath: namespace.full_path })

    assert_nil result['data']['namespace']
  end

  test 'namespace query should not return a result when unauthorized' do
    namespace = groups(:group_one)

    result = IridaSchema.execute(NAMESPACE_QUERY, context: { current_user: users(:jane_doe) },
                                                  variables: { namespacePath: namespace.full_path })

    assert_nil result['data']['group']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.group.read?', name: namespace.name), error_message
  end
end
