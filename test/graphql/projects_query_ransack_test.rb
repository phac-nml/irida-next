# frozen_string_literal: true

require 'test_helper'

class ProjectsQueryRansackTest < ActiveSupport::TestCase
  PROJECTS_RANSACK_QUERY = <<~GRAPHQL
    query($filter: ProjectFilter, $orderBy: ProjectOrder) {
      projects(filter: $filter, orderBy: $orderBy) {
        nodes {
          name
          path
          description
          id
          puid
          createdAt
        }
        totalCount
      }
    }
  GRAPHQL

  PROJECTS_RANSACK_WITH_GROUP_QUERY = <<~GRAPHQL
    query($filter: ProjectFilter, $group_id: ID!, $orderBy: ProjectOrder) {
      projects(filter: $filter, groupId: $group_id, orderBy: $orderBy) {
        nodes {
          name
          path
          description
          id
          puid
          createdAt
        }
        totalCount
      }
    }
  GRAPHQL

  PROJECTS_RANSACK_WITH_METADATA_SUMMARY_QUERY = <<~GRAPHQL
    query($filter: ProjectFilter, $orderBy: ProjectOrder, $keys: [String!]) {
      projects(filter: $filter, orderBy: $orderBy) {
        nodes {
          name
          metadataSummary(keys: $keys)
        }
        totalCount
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @project = projects(:project1)
  end

  test 'ransack projects query should work' do
    original_date = Time.zone.today
    Timecop.travel(5.days.from_now) do
      @project.created_at = Time.zone.now
      @project.save!

      result = IridaSchema.execute(PROJECTS_RANSACK_QUERY,
                                   context: { current_user: @user },
                                   variables: { filter: { created_at_gt: (original_date + 1.day).to_s } })

      assert_nil result['errors'], 'should work and have no errors.'
      data = result['data']['projects']['nodes']

      assert_equal 1, data.count
      assert_equal @project.puid, data[0]['puid']
    end
  end

  test 'ransack projects query should work with order by' do
    result = IridaSchema.execute(PROJECTS_RANSACK_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { name_cont: 'Project 1' },
                                              orderBy: { field: 'name', direction: 'asc' } })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['projects']['nodes']

    assert_equal 12, data.count # Project 1, Project 10, Project 11, etc
    assert_equal projects(:namespace_group_link_group_one_project1).puid, data[0]['puid']
    assert_equal projects(:project1).puid, data[1]['puid']
    assert_equal projects(:project10).puid, data[2]['puid']
  end

  test 'ransack projects query with group id should work' do
    original_date = Time.zone.today
    Timecop.travel(5.days.from_now) do
      @project.created_at = Time.zone.now
      @project.save!

      result = IridaSchema.execute(PROJECTS_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: @user },
                                   variables: { group_id: groups(:group_one).to_global_id.to_s,
                                                filter: { created_at_gt: (original_date + 1.day).to_s } })

      assert_nil result['errors'], 'should work and have no errors.'
      data = result['data']['projects']['nodes']

      assert_equal 1, data.count
      assert_equal @project.puid, data[0]['puid']
    end
  end

  test 'ransack projects query with group id should work with order by' do
    result = IridaSchema.execute(PROJECTS_RANSACK_WITH_GROUP_QUERY,
                                 context: { current_user: @user },
                                 variables: { group_id: groups(:group_one).to_global_id.to_s,
                                              orderBy: { field: 'name', direction: 'desc' } })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['projects']['nodes']

    assert_equal 22, data.count
    assert_equal projects(:project9).puid, data[0]['puid']
    assert_equal projects(:project8).puid, data[1]['puid']
    assert_equal projects(:project7).puid, data[2]['puid']
  end

  test 'ransack projects query should throw authorization error' do
    original_date = Time.zone.today
    Timecop.travel(5.days.from_now) do
      @project.created_at = Time.zone.now
      @project.save!

      result = IridaSchema.execute(PROJECTS_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: @user },
                                   variables: { group_id: groups(:group_a).to_global_id.to_s,
                                                filter: { created_at_gt: (original_date + 1.day).to_s } })

      assert_not_nil result['errors'], 'should not work and have authorization errors.'

      assert_equal "You are not authorized to view group #{groups(:group_a).name} on this server.",
                   result['errors'].first['message']

      data = result['data']['projects']

      assert_nil data
    end
  end

  test 'ransack group projects query should throw authorization error due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_expired_pat)
    group = groups(:group_one)
    original_date = Time.zone.today

    Timecop.travel(5.days.from_now) do
      @project.created_at = Time.zone.now
      @project.save!

      result = IridaSchema.execute(PROJECTS_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: user, token: },
                                   variables: { group_id: group.to_global_id.to_s,
                                                filter: { created_at_gt: (original_date + 1.day).to_s } })

      assert_not_nil result['errors'], 'should not work and have authorization errors.'

      assert_equal 'You are not authorized to perform this action',
                   result['errors'].first['message']

      data = result['data']['projects']

      assert_nil data
    end
  end

  test 'projects query with metadata sumamry should work' do
    result = IridaSchema.execute(PROJECTS_RANSACK_WITH_METADATA_SUMMARY_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { name_cont: 'Project 1' },
                                              orderBy: { field: 'created_at', direction: 'asc' },
                                              keys: ['metadatafield2'] })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['projects']

    assert_not_empty data, 'projects type should work'
    assert_equal 35, data['nodes'][0]['metadataSummary']['metadatafield2']
  end
end
