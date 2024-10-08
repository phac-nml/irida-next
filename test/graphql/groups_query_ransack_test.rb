# frozen_string_literal: true

require 'test_helper'

class GroupsQueryTest < ActiveSupport::TestCase
  GROUPS_RANSACK_QUERY = <<~GRAPHQL
    query($filter: GroupFilter, $orderBy: GroupOrder) {
      groups(filter: $filter, orderBy: $orderBy) {
        nodes {
          name
          id
          puid
          updatedAt
          createdAt
        }
        totalCount
      }
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'ransack groups query should work' do
    group = groups(:group_one)
    original_date = Time.zone.today
    Timecop.travel(5.days.from_now) do
      group.created_at = Time.zone.now
      group.save!

      result = IridaSchema.execute(GROUPS_RANSACK_QUERY,
                                   context: { current_user: @user },
                                   variables: { filter: { created_at_gt: (original_date + 1.day).to_s } })

      assert_nil result['errors'], 'should work and have no errors.'

      data = result['data']['groups']['nodes']

      assert_equal 1, data.count
      assert_equal group.puid, data[0]['puid']
    end
  end

  test 'ransack groups query should work with order by' do
    result = IridaSchema.execute(GROUPS_RANSACK_QUERY,
                                 context: { current_user: @user },
                                 variables: { filter: { name_start: 'Group 1' },
                                              orderBy: { field: 'name', direction: 'desc' } })

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['groups']['nodes']

    assert_equal 7, data.count # Group 1, Group 10, Group 11, etc

    assert_equal groups(:group_seventeen).name, data[0]['name']
    assert_equal groups(:group_seventeen).puid, data[0]['puid']

    assert_equal groups(:group_sixteen).name, data[1]['name']
    assert_equal groups(:group_sixteen).puid, data[1]['puid']

    assert_equal groups(:group_ten).name, data[5]['name']
    assert_equal groups(:group_ten).puid, data[5]['puid']

    assert_equal groups(:group_one).name, data[6]['name']
    assert_equal groups(:group_one).puid, data[6]['puid']
  end
end
