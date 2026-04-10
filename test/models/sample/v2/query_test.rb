# frozen_string_literal: true

require 'test_helper'

class Sample::V2::QueryTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  include AdvancedSearch::V2::Tree

  setup do
    @scope = Sample.where(project_id: projects(:project1).id)
  end

  def build_query(tree: nil, **)
    tree ||= GroupNode.new(combinator: 'and', nodes: [])
    Sample::V2::Query.new(tree:, scope: @scope, **)
  end

  test '#results returns a [Pagy, ActiveRecord::Relation] tuple' do
    query = build_query
    result = query.results
    assert_equal 2, result.length
    assert_kind_of Pagy, result.first
    assert result.last.is_a?(ActiveRecord::Relation)
  end

  test '#results with empty tree returns all samples in scope' do
    tree = GroupNode.new(combinator: 'and', nodes: [])
    query = build_query(tree:)
    _pagy, relation = query.results
    assert_equal @scope.count, relation.count
  end

  test '#results with valid tree returns filtered samples' do
    sample = samples(:sample1)
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: sample.name)]
    )
    query = build_query(tree:)
    _pagy, relation = query.results
    assert_includes relation, sample
    assert_equal 1, relation.count
  end

  test '#valid? returns true for valid tree' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: 'test')]
    )
    query = build_query(tree:)
    assert query.valid?
    assert_empty query.errors
  end

  test '#valid? returns false for invalid tree' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'bad_field', operator: '=', value: 'test')]
    )
    query = build_query(tree:)
    assert_not query.valid?
    assert_not_empty query.errors
  end

  test '#valid? returns false for nil tree' do
    query = Sample::V2::Query.new(tree: nil, scope: @scope)

    assert_not query.valid?
    assert_includes query.errors, { path: 'root', message: 'query tree is required' }
  end

  test '#errors returns TreeValidator errors when invalid' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'bad_field', operator: '=', value: 'test')]
    )
    query = build_query(tree:)
    query.valid?
    assert(query.errors.any? { |e| e[:message].include?('bad_field') })
  end

  test 'pagination limit param is respected' do
    # Use a scope with more samples than our default limit
    scope = Sample.all
    tree = GroupNode.new(combinator: 'and', nodes: [])
    query = Sample::V2::Query.new(tree:, scope:, limit: 5, page: 1)
    pagy, _relation = query.results
    assert_equal 5, pagy.limit
  end

  test 'pagination page param is respected' do
    scope = Sample.all
    tree = GroupNode.new(combinator: 'and', nodes: [])
    query = Sample::V2::Query.new(tree:, scope:, limit: 5, page: 2)
    pagy, _relation = query.results
    assert_equal 2, pagy.page
  end

  test 'sort by name asc orders results correctly' do
    scope = Sample.where(project_id: projects(:project1).id)
    tree = GroupNode.new(combinator: 'and', nodes: [])
    query = Sample::V2::Query.new(tree:, scope:, sort: 'name asc')
    _pagy, relation = query.results
    names = relation.pluck(:name)
    assert_equal names.sort, names
  end

  test 'sort by updated_at desc orders results correctly' do
    scope = Sample.where(project_id: projects(:project1).id)
    tree = GroupNode.new(combinator: 'and', nodes: [])
    query = Sample::V2::Query.new(tree:, scope:, sort: 'updated_at desc')
    _pagy, relation = query.results
    updated_ats = relation.pluck(:updated_at)
    assert_equal updated_ats.sort.reverse, updated_ats
  end
end
