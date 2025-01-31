# frozen_string_literal: true

require 'test_helper'

class ProjectSamplesQueryTest < ActiveSupport::TestCase
  PROJECT_QUERY = <<~GRAPHQL
    query($projectPath: ID!, $sampleFilter: SampleFilter, $sampleOrderBy: SampleOrder) {
      project(fullPath: $projectPath) {
        name
        path
        id
        samples(first:10, filter: $sampleFilter, orderBy: $sampleOrderBy) {
          nodes {
            id
            name
            project {
              id
            }
          }
        }
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    Sample.reindex
    Searchkick.enable_callbacks
  end

  teardown do
    Searchkick.disable_callbacks
  end

  test 'project with sample query should work' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: @user },
                                                variables: { projectPath: project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal project.samples.count, data['samples']['nodes'].count

    # verify fetched sample data matches data on project
    project.samples.each_with_index do |sample, index|
      assert_equal sample.name, data['samples']['nodes'][index]['name']
      assert_equal sample.to_global_id.to_s, data['samples']['nodes'][index]['id']
      assert_equal project.to_global_id.to_s, data['samples']['nodes'][index]['project']['id']
    end
  end

  test 'project with sample query should work for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: user, token: },
                                                variables: { projectPath: project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal project.samples.count, data['samples']['nodes'].count

    # verify fetched sample data matches data on project
    project.samples.each_with_index do |sample, index|
      assert_equal sample.name, data['samples']['nodes'][index]['name']
      assert_equal sample.to_global_id.to_s, data['samples']['nodes'][index]['id']
      assert_equal project.to_global_id.to_s, data['samples']['nodes'][index]['project']['id']
    end
  end

  test 'project with sample query should not work for uploader access level with expired token' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: user, token: },
                                                variables: { projectPath: project.full_path })

    assert_nil result['data']['project']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal I18n.t('action_policy.policy.project.read?', name: project.name), error_message
  end

  test 'project with sample query should work with filter' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: @user },
                                                variables: { projectPath: project.full_path,
                                                             sampleFilter: { name_or_puid_cont: 'Sample 2' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal 2, data['samples']['nodes'].count

    # verify fetched sample data only includes ones with `Sample 2` in the name
    project.samples.where('name ILIKE \'%Sample 2%\'').each_with_index do |sample, index|
      assert_equal sample.name, data['samples']['nodes'][index]['name']
      assert_equal sample.to_global_id.to_s, data['samples']['nodes'][index]['id']
      assert_equal project.to_global_id.to_s, data['samples']['nodes'][index]['project']['id']
    end
  end

  test 'project with sample query should work with order by' do
    project = projects(:project1)

    result = IridaSchema.execute(PROJECT_QUERY, context: { current_user: @user },
                                                variables: { projectPath: project.full_path,
                                                             sampleOrderBy: { field: 'created_at', direction: 'asc' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']

    assert_equal project.to_global_id.to_s, data['id'], 'id should be GlobalID'
    assert_equal project.samples.count, data['samples']['nodes'].count

    # verify fetched sample data matches data on project
    project.samples.order(created_at: :asc).each_with_index do |sample, index|
      assert_equal sample.name, data['samples']['nodes'][index]['name']
      assert_equal sample.to_global_id.to_s, data['samples']['nodes'][index]['id']
      assert_equal project.to_global_id.to_s, data['samples']['nodes'][index]['project']['id']
    end
  end
end
