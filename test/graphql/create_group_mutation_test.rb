# frozen_string_literal: true

require 'test_helper'

class CreateProjectMutationTest < ActiveSupport::TestCase
  CREATE_GROUP_MUTATION = <<~GRAPHQL
    mutation($name: String!, $description: String!) {
      createGroup(input: { name: $name, description: $description }) {
        errors {
          path
          message
        }
        group {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_SUBGROUP_USING_GROUP_ID_MUTATION = <<~GRAPHQL
    mutation($groupId: ID!, $name: String!, $description: String!) {
      createGroup(input: { groupId: $groupId, name: $name, description: $description }) {
        errors {
          path
          message
        }
        group {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_SUBGROUP_USING_GROUP_PUID_MUTATION = <<~GRAPHQL
    mutation($groupPuid: ID!, $name: String!, $description: String!) {
      createGroup(input: { groupPuid: $groupPuid, name: $name, description: $description }) {
        errors {
          path
          message
        }
        group {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_GROUP_MUTATION_WITH_CUSTOM_PATH = <<~GRAPHQL
    mutation($name: String!, $description: String!, $path: String!) {
      createGroup(input: { name: $name, description: $description, path: $path }) {
        errors {
          path
          message
        }
        group {
          id
          name
          description
          path
          fullPath
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
  end

  test 'createGroup mutation should work with valid params, parent group global id, and api scope token' do
    parent_group = groups(:group_one)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Group One',
                                              description: 'New Group One Description',
                                              groupId: parent_group.to_global_id.to_s })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createGroup']

    assert_not_empty data, 'createGroup should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['group']

    assert_equal 'New Group One', data['group']['name']
    assert_equal 'New Group One Description', data['group']['description']

    group = Group.last
    # Top level group
    assert_equal parent_group.to_global_id, group.parent.to_global_id
    assert_equal 'new-group-one', group.path
    assert_equal 'group-1/new-group-one', group.full_path
  end

  test 'createGroup mutation should work with valid params, parent group puid, and api scope token' do
    parent_group = groups(:group_one)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Group One',
                                              description: 'New Group One Description',
                                              groupPuid: parent_group.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createGroup']

    assert_not_empty data, 'createGroup should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['group']

    assert_equal 'New Group One', data['group']['name']
    assert_equal 'New Group One Description', data['group']['description']

    group = Group.last
    # Top level group
    assert_equal parent_group.puid, group.parent.puid
    assert_equal 'new-group-one', group.path
    assert_equal 'group-1/new-group-one', group.full_path
  end

  test 'createGroup mutation should work with valid params, no parent group id/puid, and api scope token' do
    result = IridaSchema.execute(CREATE_GROUP_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Group One',
                                              description: 'New Group One Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createGroup']

    assert_not_empty data, 'createGroup should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['group']

    assert_equal 'New Group One', data['group']['name']
    assert_equal 'New Group One Description', data['group']['description']

    group = Group.last
    # Top level group
    assert_nil group.parent
    assert_equal 'new-group-one', group.path
    assert_equal 'new-group-one', group.full_path
  end

  test 'createGroup mutation should work with custom path' do
    result = IridaSchema.execute(CREATE_GROUP_MUTATION_WITH_CUSTOM_PATH,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Group Two',
                                              description: 'New Group Two Description',
                                              path: 'my-custom-path' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createGroup']

    assert_not_empty data, 'createGroup should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['group']

    assert_equal 'New Group Two', data['group']['name']
    assert_equal 'New Group Two Description', data['group']['description']

    group = Group.last
    assert_equal 'my-custom-path', group.path
    assert_equal 'my-custom-path', group.full_path
  end

  test 'createGroup mutation should not work with invalid custom path' do
    result = IridaSchema.execute(CREATE_GROUP_MUTATION_WITH_CUSTOM_PATH,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Group Two',
                                              description: 'New Group Two Description',
                                              path: 'Invalid Custom Path' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createGroup']

    assert_not_empty data, 'createGroup should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_nil data['group']

    assert_equal 1, data['errors'].count
    expected_error = { 'path' => %w[group path], 'message' => 'Namespace Path is not valid' }

    assert_equal expected_error, data['errors'][0]
  end

  test 'createGroup mutation should not work with valid params, and api scope token with uploader access level' do
    user = users(:groupJeff_bot)
    token = personal_access_tokens(:groupJeff_bot_account_valid_pat)
    parent_group = groups(:group_jeff)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { groupId: parent_group.to_global_id.to_s,
                                              name: 'New Group Two',
                                              description: 'New Group Two Description' })

    assert_not_empty result['errors'], 'should have errors.'

    errors = result['errors']

    expected_error = 'You are not authorized to create a subgroup within group Group Jeff on this server.'

    assert_equal expected_error, errors[0]['message']
  end

  test 'createGroup mutation should not work with valid params and read api scope token' do
    result = IridaSchema.execute(CREATE_GROUP_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { name: 'New Group One',
                                              description: 'New Group One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'createGroup mutation should not work with unauthorized group and valid api scope token' do
    group = groups(:janitor_doe_group)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupPuid: group.puid,
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to create a subgroup within group Group EndToEnd on this server.',
                 error_message
  end

  test 'createGroup mutation should not work with invalid parent group puid and valid api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupPuid: "INVALID#{group.puid}",
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['data']['createGroup']['errors'], 'shouldn\'t work and have errors.'

    errors = result['data']['createGroup']['errors']

    assert_equal 'Group not found by provided ID or PUID', errors[0]['message']
  end

  test 'createGroup mutation should not work with invalid parent group id and valid api scope token' do
    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupId: 'gid://irida/Project/not-a-valid-uuid',
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error = result['errors'][0]['message']

    assert_equal 'gid://irida/Project/not-a-valid-uuid is not a valid ID for Group', error
  end

  test 'createGroup mutation should not work with bad formatted parent group id and valid api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_SUBGROUP_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupId: "INVALID#{group.id}",
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error = result['errors'][0]['message']

    assert_equal 'INVALIDc104036c-0ab5-5f7e-9e56-e1c13819e96d is not a valid IRIDA Next ID.', error
  end
end
