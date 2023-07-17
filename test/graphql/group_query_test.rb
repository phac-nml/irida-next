# frozen_string_literal: true

require 'test_helper'

class GroupQueryTest < ActiveSupport::TestCase
  GROUP_QUERY = <<~GRAPHQL
    query($groupPath: ID!, $includeParentDescendants: Boolean) {
      group(fullPath: $groupPath) {
        name
        path
        description
        id
        fullName
        fullPath
        descendantGroups(includeParentDescendants: $includeParentDescendants) {
          nodes {
            name
            path
          }
          totalCount
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'group query should work' do
    group = groups(:group_one)

    result = IridaSchema.execute(GROUP_QUERY, context: { current_user: @user },
                                              variables: { groupPath: group.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['group']

    assert_not_empty data, 'group type should work'
    assert_equal group.name, data['name']

    assert_equal group.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'group query should work when not including parent descendants' do
    group = groups(:group_one)

    result = IridaSchema.execute(GROUP_QUERY, context: { current_user: @user },
                                              variables: { groupPath: group.full_path,
                                                           includeParentDescendants: false })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['group']

    assert_not_empty data, 'group type should work'
    assert_equal group.name, data['name']

    assert_equal group.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'group query should not return a result when unauthorized' do
    group = groups(:group_one)

    result = IridaSchema.execute(GROUP_QUERY, context: { current_user: users(:jane_doe) },
                                              variables: { groupPath: group.full_path })

    assert_nil result['data']['group']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.group.read?', name: group.name), error_message
  end

  test 'group query should not return a result when unauthorized a' do
    group = groups(:david_doe_group_four)

    result = IridaSchema.execute(GROUP_QUERY, context: { current_user: @user },
                                              variables: { groupPath: group.full_path })

    assert_nil result['data']['group']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.group.read?', name: group.name), error_message
  end
end
