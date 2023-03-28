# frozen_string_literal: true

require 'test_helper'

class BreadcrumbComponentTest < ViewComponent::TestCase
  def test_single_path
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock request
    mock_request = ActionDispatch::TestRequest.create(Rack::MockRequest.env_for("/#{mock_route.path}"))

    render_inline(BreadcrumbComponent.new(route: mock_route, request: mock_request))
    assert_text groups(:group_one).name
    assert_no_text I18n.t('views.groups.edit', raise: true)
    assert_selector 'a', count: 1
    assert_none_of_selectors 'svg'
  end

  def test_compound_path
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock request
    mock_request = ActionDispatch::TestRequest.create(Rack::MockRequest.env_for("/#{mock_route.path}/-/edit"))

    render_inline(BreadcrumbComponent.new(route: mock_route, request: mock_request))
    assert_text groups(:group_one).name
    assert_text I18n.t('views.groups.edit', raise: true)
    assert_selector 'a', count: 2
    assert_selector 'svg', count: 1
  end
end
