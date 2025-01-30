# frozen_string_literal: true

require 'test_helper'

class SamplesQueryRansackTest < ActiveSupport::TestCase
  SAMPLES_RANSACK_QUERY = <<~GRAPHQL
    query($filter: SampleFilter, $orderBy: SampleOrder) {
      samples(filter: $filter, orderBy: $orderBy) {
        nodes {
          name
          description
          id
          puid
          createdAt
          project {
            id
          }
        }
        totalCount
      }
    }
  GRAPHQL

  SAMPLES_RANSACK_WITH_GROUP_QUERY = <<~GRAPHQL
    query($filter: SampleFilter, $group_id: ID!, $orderBy: SampleOrder) {
      samples(filter: $filter, groupId: $group_id, orderBy: $orderBy) {
        nodes {
          name
          description
          id
          puid
          createdAt
          project {
            id
          }
        }
        totalCount
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
    @sample = samples(:sample1)
    @sample32 = samples(:sample32)
  end

  test 'filter samples should work' do
    original_date = Time.zone.today
    Timecop.travel(5.days.from_now) do
      @sample.created_at = Time.zone.now
      @sample.save!

      result = IridaSchema.execute(SAMPLES_RANSACK_QUERY,
                                   context: { current_user: @user },
                                   variables: { filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                     field: 'created_at', operator: '>=', value: (original_date + 1.day).to_s
                                   }] }] } })

      assert_nil result['errors'], 'should work and have no errors.'

      data = result['data']['samples']['nodes']

      assert_equal 1, data.count
      assert_equal @sample.puid, data[0]['puid']
    end
  end

  test 'filter samples should work with order by' do
    result = IridaSchema.execute(SAMPLES_RANSACK_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                   field: 'name', operator: 'contains', value: 'Project 1'
                                 }] }] }, orderBy: { field: 'created_at', direction: 'asc' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']['nodes']
    assert_equal 3, data.count

    # assert_equal samples(:sample2).name, data[0]['name']
    # assert_equal samples(:sample2).puid, data[0]['puid']

    # assert_equal samples(:sample1).name, data[1]['name']
    # assert_equal samples(:sample1).puid, data[1]['puid']

    # assert_equal samples(:sample37).name, data[2]['name']
    # assert_equal samples(:sample37).puid, data[2]['puid']
  end

  test 'filter group samples with group id should work' do
    original_date = Time.zone.today

    Timecop.travel(5.days.from_now) do
      @sample.created_at = Time.zone.now
      @sample.save!

      result = IridaSchema.execute(SAMPLES_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: @user },
                                   variables: { group_id: groups(:group_one).to_global_id.to_s,
                                                filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                                  field: 'created_at', operator: '>=', value: (original_date + 1.day).to_s
                                                }] }] } })

      assert_nil result['errors'], 'should work and have no errors.'

      data = result['data']['samples']['nodes']

      assert_equal 1, data.count
      assert_equal @sample.puid, data[0]['puid']
    end
  end

  test 'filter group samples with group id should work with order by' do
    result = IridaSchema.execute(SAMPLES_RANSACK_WITH_GROUP_QUERY,
                                 context: { current_user: @user },
                                 variables: { group_id: groups(:group_one).to_global_id.to_s,
                                              orderBy: { field: 'created_at', direction: 'asc' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']['nodes']
    assert_equal 25, data.count

    # assert_equal samples(:sample30).name, data[0]['name']
    # assert_equal samples(:sample30).puid, data[0]['puid']

    # assert_equal samples(:sample29).name, data[1]['name']
    # assert_equal samples(:sample29).puid, data[1]['puid']

    # assert_equal samples(:sample28).name, data[2]['name']
    # assert_equal samples(:sample28).puid, data[2]['puid']
  end

  test 'filter group samples should throw authorization error' do
    original_date = Time.zone.today

    Timecop.travel(5.days.from_now) do
      @sample.created_at = Time.zone.now
      @sample.save!

      result = IridaSchema.execute(SAMPLES_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: @user },
                                   variables: { group_id: groups(:group_a).to_global_id.to_s,
                                                filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                                  field: 'created_at', operator: '>=', value: (original_date + 1.day).to_s
                                                }] }] } })

      assert_not_nil result['errors'], 'should not work and have authorization errors.'

      assert_equal "You are not authorized to view samples for group #{groups(:group_a).name} on this server.",
                   result['errors'].first['message']

      data = result['data']['samples']

      assert_nil data
    end
  end

  test 'filter group samples should throw authorization error due to expired token for uploader access level' do
    user = users(:user_bot_account0)
    token = personal_access_tokens(:user_bot_account0_valid_pat)
    group = groups(:group_one)
    original_date = Time.zone.today

    Timecop.travel(5.days.from_now) do
      @sample.created_at = Time.zone.now
      @sample.save!

      result = IridaSchema.execute(SAMPLES_RANSACK_WITH_GROUP_QUERY,
                                   context: { current_user: user, token: },
                                   variables: { group_id: group.to_global_id.to_s,
                                                filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                                  field: 'created_at', operator: '>=', value: (original_date + 1.day).to_s
                                                }] }] } })

      assert_not_nil result['errors'], 'should not work and have authorization errors.'

      assert_equal "You are not authorized to view samples for group #{group.name} on this server.",
                   result['errors'].first['message']

      data = result['data']['samples']

      assert_nil data
    end
  end

  test 'filter samples with existing metadata field using advanced search should work' do
    result = IridaSchema.execute(SAMPLES_RANSACK_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                   field: 'metadata.metadatafield1', operator: 'exists'
                                 }] }] } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']['nodes']

    assert_equal 4, data.count
  end

  test 'filter samples with metadata field using advanced search should work' do
    result = IridaSchema.execute(SAMPLES_RANSACK_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { advanced_search_groups: [{ advanced_search_conditions: [{
                                   field: 'metadata.metadatafield1', operator: '=', value: 'value1'
                                 }] }] } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']['nodes']

    assert_equal 4, data.count
  end

  test 'filter group samples with sample name using advanced search should work' do
    result = IridaSchema.execute(SAMPLES_RANSACK_WITH_GROUP_QUERY,
                                 context: { current_user: @user },
                                 variables: { group_id: groups(:group_one).to_global_id.to_s,
                                              filter: { advanced_search_groups: [{ advanced_search_conditions:
                                 [{ field: 'name', operator: '=', value: 'Project 1 Sample 1' }] }] } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['samples']['nodes']

    assert_equal 1, data.count
  end
end
