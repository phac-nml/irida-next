# frozen_string_literal: true

require 'test_helper'

class NamespaceRowPresenterTest < ActiveSupport::TestCase
  test 'memoizes group values used by a namespace row' do
    group = Group.new
    children_count_calls = 0
    project_namespaces_count_calls = 0
    aggregated_samples_count_calls = 0
    children = Object.new
    project_namespaces = Object.new

    children.define_singleton_method(:size) do
      children_count_calls += 1
      2
    end
    project_namespaces.define_singleton_method(:size) do
      project_namespaces_count_calls += 1
      3
    end
    group.define_singleton_method(:children) { children }
    group.define_singleton_method(:project_namespaces) { project_namespaces }
    group.define_singleton_method(:aggregated_samples_count) do
      aggregated_samples_count_calls += 1
      4
    end

    Member.expects(:effective_access_level).once.returns(Member::AccessLevel::MAINTAINER)
    presenter = NamespaceRowPresenter.new(namespace: group, user: users(:john_doe))

    assert_equal Member::AccessLevel::MAINTAINER, presenter.access_level
    assert_equal Member::AccessLevel::MAINTAINER, presenter.access_level
    assert_equal 2, presenter.children_count
    assert_equal 2, presenter.children_count
    assert_equal 3, presenter.project_namespaces_count
    assert_equal 3, presenter.project_namespaces_count
    assert_equal 4, presenter.aggregated_samples_count
    assert_equal 4, presenter.aggregated_samples_count
    assert_predicate presenter, :expandable?

    assert_equal 1, children_count_calls
    assert_equal 1, project_namespaces_count_calls
    assert_equal 1, aggregated_samples_count_calls
  end

  test 'uses the precomputed aggregated samples count' do
    group = Group.new
    group.define_singleton_method(:aggregated_samples_count) { flunk }

    presenter = NamespaceRowPresenter.new(namespace: group, user: users(:john_doe), aggregated_samples_count: 4)

    assert_equal 4, presenter.aggregated_samples_count
  end

  test 'memoizes project namespace samples count from the counter cache' do
    project_namespace = Namespaces::ProjectNamespace.new
    samples_count_calls = 0
    project = Object.new
    project.define_singleton_method(:samples_count) do
      samples_count_calls += 1
      5
    end
    project_namespace.define_singleton_method(:project) { project }

    presenter = NamespaceRowPresenter.new(namespace: project_namespace, user: users(:john_doe))

    assert_equal 5, presenter.samples_count
    assert_equal 5, presenter.samples_count
    assert_equal 1, samples_count_calls
  end

  test 'uses the precomputed samples count' do
    project_namespace = Namespaces::ProjectNamespace.new
    project_namespace.define_singleton_method(:project) { flunk }

    presenter = NamespaceRowPresenter.new(namespace: project_namespace, user: users(:john_doe), samples_count: 5)

    assert_equal 5, presenter.samples_count
  end

  test 'builds a presenter per namespace and batches aggregated samples counts for groups only' do
    group = groups(:group_one)
    project_namespace = namespaces_project_namespaces(:project1_namespace)

    Namespaces::AggregatedSamplesCountsService.expects(:new)
                                              .with(groups: [group])
                                              .returns(stub(execute: { group.id => 7 }))

    presenters = NamespaceRowPresenter.build_collection(namespaces: [group, project_namespace], user: users(:john_doe))

    assert_equal 7, presenters.fetch(group.id).aggregated_samples_count
    assert_equal project_namespace, presenters.fetch(project_namespace.id).namespace
  end
end
