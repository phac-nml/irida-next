# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class BreadcrumbComponentTest < ViewComponentTestCase
    include RouteHelper
    test 'single path' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb

      context_crumbs = route_to_context_crumbs(mock_route)
      context_crumbs += [{ name: I18n.t('groups.edit.title', raise: true), path: groups(:group_one).path }]

      render_inline(Viral::BreadcrumbComponent.new(context_crumbs:))
      assert_text groups(:group_one).name
      assert_selector 'li[class~="md:visible"] a', count: 2
      assert_selector 'li[class~="md:visible"] svg', count: 1
    end

    test 'compound path' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = route_to_context_crumbs(mock_route)
      context_crumbs += [{ name: I18n.t('projects.edit.title', raise: true),
                           path: "#{groups(:group_one).path}/-/edit" }]

      render_inline(Viral::BreadcrumbComponent.new(context_crumbs:))
      assert_text groups(:group_one).name
      assert_text I18n.t('groups.edit.title', raise: true)
      assert_selector 'li[class~="md:visible"] a', count: 2
      assert_selector 'li[class~="md:visible"] svg', count: 1
    end

    test 'route with no extra crumbs' do
      # Mock route
      mock_route = routes(:group_one_route)

      context_crumbs = route_to_context_crumbs(mock_route)

      render_inline(Viral::BreadcrumbComponent.new(context_crumbs:))
      assert_text groups(:group_one).name
      assert_selector 'li[class~="md:visible"] a', count: 1
    end

    test 'compound path with missing translation' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = route_to_context_crumbs(mock_route)
      context_crumbs += [{ name: I18n.t('projects.edit.title', raise: true),
                           path: "#{groups(:group_one).path}/-/groups/new" }]

      render_inline(Viral::BreadcrumbComponent.new(context_crumbs:))
      assert_text groups(:group_one).name
      assert_selector 'li[class~="md:visible"] a', count: 2
      assert_selector 'li[class~="md:visible"] svg', count: 1
    end

    test 'context crumbs not an array' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = { name: I18n.t('groups.edit.title', raise: true), path: groups(:group_one).path }

      assert_raises ArgumentError do
        render_inline(Viral::BreadcrumbComponent.new(route: mock_route, context_crumbs:))
      end
    end

    test 'context crumbs without hash' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = ['FOOBAR']

      assert_raises ArgumentError do
        render_inline(Viral::BreadcrumbComponent.new(route: mock_route, context_crumbs:))
      end
    end

    test 'context crumbs without name' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = [{ path: groups(:group_one).path }]

      assert_raises ArgumentError do
        render_inline(Viral::BreadcrumbComponent.new(route: mock_route, context_crumbs:))
      end
    end

    test 'context crumbs without path' do
      # Mock route
      mock_route = routes(:group_one_route)

      # Mock context breadcrumb
      context_crumbs = [{ name: I18n.t('groups.edit.title', raise: true) }]

      assert_raises ArgumentError do
        render_inline(Viral::BreadcrumbComponent.new(route: mock_route, context_crumbs:))
      end
    end
  end
end
