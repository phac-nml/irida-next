# frozen_string_literal: true

class RouteHelperTest < ActionView::TestCase
  include RouteHelper

  test 'convert route to context crumbs' do
    mock_route = routes(:group_one_route)

    context_crumbs = route_to_context_crumbs(mock_route)
    assert_equal(context_crumbs, [{ name: 'Group 1', path: 'group-1' }])
  end
end
