# frozen_string_literal: true

require 'test_helper'

class RouteTest < ActiveSupport::TestCase
  def setup
    @route = routes(:group_one_route)
  end

  test 'valid route' do
    assert @route.valid?
  end

  test 'invalid without path' do
    @route.path = nil
    assert_not @route.valid?
  end

  test 'invalid without source' do
    @route.source = nil
    assert_not @route.valid?
  end

  test '#inside_path' do
    @subgroup8_route = routes(:subgroup8_route)
    @subgroup9_route = routes(:subgroup9_route)

    assert_includes Route.inside_path(@subgroup8_route.path), @subgroup9_route
  end

  test '#rename_descendants' do
    @subgroup8_route = routes(:subgroup8_route)
    @subgroup9_route = routes(:subgroup9_route)
    old_subgroup9_route_path = @subgroup9_route.path
    old_subgroup9_route_name = @subgroup9_route.name

    @subgroup8_route.update(path: 'new-subgroup-8')
    assert_not_equal old_subgroup9_route_path, @subgroup9_route.reload.path

    @subgroup8_route.update(name: 'New Subgroup 8')
    assert_not_equal old_subgroup9_route_name, @subgroup9_route.reload.name
  end

  test 'split_path_parts' do
    split_paths = routes(:subgroup1_route).split_path_parts
    assert_equal ['group-1', 'group-1/subgroup-1'], split_paths
  end
end
