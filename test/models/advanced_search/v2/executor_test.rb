# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::ExecutorTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  include AdvancedSearch::V2::Tree

  setup do
    @scope = Sample.all
  end

  test 'empty nodes array returns base scope unchanged' do
    tree = GroupNode.new(combinator: 'and', nodes: [])
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_equal @scope.to_sql, result.to_sql
  end

  test 'single condition with name equals returns only matching samples' do
    sample = samples(:sample1)
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: sample.name)]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_includes result, sample
    assert(result.all? { |s| s.name == sample.name })
  end

  test 'AND group with 2 conditions returns intersection' do
    # Find a sample that has specific metadata, use name + puid
    sample = samples(:sample1)
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [
        ConditionNode.new(field: 'name', operator: '=', value: sample.name),
        ConditionNode.new(field: 'puid', operator: '=', value: sample.puid)
      ]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_includes result, sample
    assert_equal 1, result.count
  end

  test 'OR group with 2 conditions returns union' do
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    tree = GroupNode.new(
      combinator: 'or',
      nodes: [
        ConditionNode.new(field: 'name', operator: '=', value: sample1.name),
        ConditionNode.new(field: 'name', operator: '=', value: sample2.name)
      ]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_includes result, sample1
    assert_includes result, sample2
  end

  test 'nested AND group containing OR sub-group produces correct results' do
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    sub_group = GroupNode.new(
      combinator: 'or',
      nodes: [
        ConditionNode.new(field: 'name', operator: '=', value: sample1.name),
        ConditionNode.new(field: 'name', operator: '=', value: sample2.name)
      ]
    )
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [
        sub_group,
        ConditionNode.new(field: 'puid', operator: '=', value: sample1.puid)
      ]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    # The AND limits to sample1's puid, so only sample1 should appear
    assert_includes result, sample1
    assert_not_includes result, sample2
  end

  test 'metadata field condition returns matching samples' do
    # sample43 fixture has metadata: { insdc_accession: 'ERR86724108' }
    sample = samples(:sample43)
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'metadata.insdc_accession', operator: '=', value: 'ERR86724108')]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_includes result, sample
  end

  test 'puid condition is case-insensitive (upcase normalization)' do
    sample = samples(:sample1)
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'puid', operator: '=', value: sample.puid.downcase)]
    )
    result = AdvancedSearch::V2::Executor.new(tree, @scope).call
    assert_includes result, sample
  end
end
