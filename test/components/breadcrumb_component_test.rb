# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class BreadcrumbComponentTest < ViewComponent::TestCase
  class MockRequest
    def initialize(path:, controller:, action:)
      @path = path
      @params = { controller:, action: }
    end

    attr_reader :path, :params
  end

  def test_single_path
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = [{ name: I18n.t('groups.edit.title', raise: true), path: groups(:group_one).path }]

    render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    assert_text groups(:group_one).name
    assert_selector 'a', count: 2
    assert_selector 'svg', count: 1
  end

  def test_compound_path
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = [{ name: I18n.t('projects.edit.title', raise: true), path: "#{groups(:group_one).path}/-/edit`" }]

    render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    assert_text groups(:group_one).name
    assert_text I18n.t('groups.edit.title', raise: true)
    assert_selector 'a', count: 2
    assert_selector 'svg', count: 1
  end

  def test_compound_path_with_missing_translation
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = [{ name: I18n.t('projects.edit.title', raise: true),
                        path: "#{groups(:group_one).path}/-/groups/new`" }]

    render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    assert_text groups(:group_one).name
    assert_selector 'a', count: 2
    assert_selector 'svg', count: 1
  end

  def test_context_crumbs_not_an_array
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = { name: I18n.t('groups.edit.title', raise: true), path: groups(:group_one).path }

    assert_raises ArgumentError do
      render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    end
  end

  def test_context_crumbs_without_hash
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = ['FOOBAR']

    assert_raises ArgumentError do
      render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    end
  end

  def test_context_crumbs_without_name
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = [{ path: groups(:group_one).path }]

    assert_raises ArgumentError do
      render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    end
  end

  def test_context_crumbs_without_path
    # Mock route
    mock_route = routes(:group_one_route)

    # Mock context breadcrumb
    context_crumbs = [{ name: I18n.t('groups.edit.title', raise: true) }]

    assert_raises ArgumentError do
      render_inline(BreadcrumbComponent.new(route: mock_route, context_crumbs:))
    end
  end
end
