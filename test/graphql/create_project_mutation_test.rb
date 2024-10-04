# frozen_string_literal: true

require 'test_helper'

class CreateProjectMutationTest < ActiveSupport::TestCase
  CREATE_PROJECT_MUTATION = <<~GRAPHQL
    mutation($name: String!, $description: String!) {
      createProject(input: { name: $name, description: $description }) {
        errors {
          path
          message
        }
        project {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_PROJECT_USING_GROUP_ID_MUTATION = <<~GRAPHQL
    mutation($groupId: ID!, $name: String!, $description: String!) {
      createProject(input: { groupId: $groupId, name: $name, description: $description }) {
        errors {
          path
          message
        }
        project {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_PROJECT_USING_GROUP_PUID_MUTATION = <<~GRAPHQL
    mutation($groupPuid: ID!, $name: String!, $description: String!) {
      createProject(input: { groupPuid: $groupPuid, name: $name, description: $description }) {
        errors {
          path
          message
        }
        project {
          id
          name
          description
        }
      }
    }
  GRAPHQL

  CREATE_PROJECT_MUTATION_WITH_CUSTOM_PATH = <<~GRAPHQL
    mutation($name: String!, $description: String!, $path: String!) {
      createProject(input: { name: $name, description: $description, path: $path }) {
        errors {
          path
          message
        }
        project {
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

  test 'createProject mutation should work with valid params, group global id, and api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupId: group.to_global_id.to_s,
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createProject']

    assert_not_empty data, 'createProject should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['project']

    assert_equal 'New Project One', data['project']['name']
    assert_equal 'New Project One Description', data['project']['description']

    project = Project.last
    assert_equal group.id, project.parent.id
    assert_equal 'new-project-one', project.path
    assert_equal 'group-1/new-project-one', project.full_path
  end

  test 'createProject mutation should work with valid params, group puid, and api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupPuid: group.puid,
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createProject']

    assert_not_empty data, 'createProject should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['project']

    assert_equal 'New Project One', data['project']['name']
    assert_equal 'New Project One Description', data['project']['description']

    project = Project.last
    assert_equal group.puid, project.parent.puid
    assert_equal 'new-project-one', project.path
    assert_equal 'group-1/new-project-one', project.full_path
  end

  test 'createProject mutation should work with valid params, no group id/puid, and api scope token' do
    result = IridaSchema.execute(CREATE_PROJECT_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createProject']

    assert_not_empty data, 'createProject should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['project']

    assert_equal 'New Project One', data['project']['name']
    assert_equal 'New Project One Description', data['project']['description']

    project = Project.last
    assert_equal @user.namespace.puid, project.parent.puid
    assert_equal 'new-project-one', project.path
    assert_equal 'john.doe_at_localhost/new-project-one', project.full_path
  end

  test 'createProject mutation should work with custom path' do
    result = IridaSchema.execute(CREATE_PROJECT_MUTATION_WITH_CUSTOM_PATH,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Project One',
                                              description: 'New Project One Description',
                                              path: 'new-custom-path' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createProject']

    assert_not_empty data, 'createProject should be populated when no authorization errors'
    assert_empty data['errors']
    assert_not_empty data['project']

    assert_equal 'New Project One', data['project']['name']
    assert_equal 'new-custom-path', data['project']['path']
    assert_equal 'john.doe_at_localhost/new-custom-path', data['project']['fullPath']
  end

  test 'createProject mutation should not work with invalid custom path' do
    result = IridaSchema.execute(CREATE_PROJECT_MUTATION_WITH_CUSTOM_PATH,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { name: 'New Project One',
                                              description: 'New Project One Description',
                                              path: 'Invalid Custom Path' })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['createProject']

    assert_not_empty data, 'createProject should be populated when no authorization errors'
    assert_not_empty data['errors']
    assert_empty data['project']

    assert_equal 1, data['errors'].count
    expected_error = { path: ['project', 'namespace.path'], message: 'Namespace Path is not valid' }

    assert_equal expected_error, data['errors'][0]
  end

  test 'createProject mutation should not work with valid params, and api scope token with uploader access level' do
    user = users(:groupJeff_bot)
    token = personal_access_tokens(:groupJeff_bot_account_valid_pat)
    group = groups(:group_jeff)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_ID_MUTATION,
                                 context: { current_user: user, token: },
                                 variables: { groupId: group.to_global_id.to_s,
                                              name: 'New Project Two',
                                              description: 'New Project Two Description' })

    assert_not_empty result['errors'], 'should have errors.'

    errors = result['errors']

    expected_error = 'You are not authorized to create a project under group Group Jeff on this server.'

    assert_equal expected_error, errors[0]['message']
  end

  test 'createProject mutation should not work with valid params and read api scope token' do
    result = IridaSchema.execute(CREATE_PROJECT_MUTATION,
                                 context: { current_user: @user, token: @read_api_scope_token },
                                 variables: { name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to perform this action', error_message
  end

  test 'createProject mutation should not work with unauthorized group and valid api scope token' do
    group = groups(:janitor_doe_group)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupPuid: group.puid,
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'You are not authorized to create a project under group Group EndToEnd on this server.', error_message
  end

  test 'createProject mutation should not work with invalid project puid and valid api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_PUID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupPuid: "INVALID#{group.puid}",
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['data']['createProject']['errors'], 'shouldn\'t work and have errors.'

    errors = result['data']['createProject']['errors']

    assert_equal 'Group not found by provided ID or PUID', errors[0]['message']
  end

  test 'createProject mutation should not work with invalid group id and valid api scope token' do
    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupId: 'gid://irida/Project/not-a-valid-uuid',
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error = result['errors'][0]['message']

    assert_equal 'gid://irida/Project/not-a-valid-uuid is not a valid ID for Group', error
  end

  test 'createProject mutation should not work with bad formatted group id and valid api scope token' do
    group = groups(:group_one)

    result = IridaSchema.execute(CREATE_PROJECT_USING_GROUP_ID_MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { groupId: "INVALID#{group.id}",
                                              name: 'New Project One',
                                              description: 'New Project One Description' })

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error = result['errors'][0]['message']

    assert_equal 'INVALIDc104036c-0ab5-5f7e-9e56-e1c13819e96d is not a valid IRIDA Next ID.', error
  end
end
