# frozen_string_literal: true

require 'test_helper'

class SampleQueryTest < ActiveSupport::TestCase
  SAMPLE_QUERY = <<~GRAPHQL
    query($samplePuid: ID!) {
      sample(puid: $samplePuid) {
        name
        description
        id
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'sample query should work' do
    project = projects(:project1)
    sample = project.samples.first

    result = IridaSchema.execute(SAMPLE_QUERY, context: { current_user: @user },
                                               variables: { samplePuid: sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'
    assert_equal sample.name, data['name']

    assert_equal sample.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'sample query should work for uploader access level' do
    user = users(:user_bot_account0)
    project = projects(:project1)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    sample = project.samples.first

    result = IridaSchema.execute(SAMPLE_QUERY, context: { current_user: user, token: },
                                               variables: { samplePuid: sample.puid })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['sample']

    assert_not_empty data, 'sample type should work'
    assert_equal sample.name, data['name']

    assert_equal sample.to_global_id.to_s, data['id'], 'id should be GlobalID'
  end

  test 'sample query should not return a result when unauthorized' do
    project = projects(:project1)
    sample = project.samples.first

    result = IridaSchema.execute(SAMPLE_QUERY, context: { current_user: users(:jane_doe) },
                                               variables: { samplePuid: sample.puid })

    assert_nil result['data']['sample']

    assert_not_nil result['errors'], 'shouldn\'t work and have errors.'

    error_message = result['errors'][0]['message']

    assert_equal 'An object of type Sample was hidden due to permissions', error_message
  end
end
