# frozen_string_literal: true

require 'test_helper'

class ProjectSamplesQueryTest < ActiveSupport::TestCase
  PROJECT_QUERY = <<~GRAPHQL
    query($projectPath: ID!) {
      project(fullPath: $projectPath) {
        name
        path
        id
        samples(first:10) {
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
      assert_equal data['samples']['nodes'][index]['id'], sample.to_global_id.to_s
      assert_equal data['samples']['nodes'][index]['name'], sample.name
      assert_equal data['samples']['nodes'][index]['project']['id'], project.to_global_id.to_s
    end
  end
end
