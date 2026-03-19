# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::Tree::GroupNodeTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  def condition
    AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: '=', value: 'x')
  end

  test 'stores combinator and nodes' do
    node = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'and', nodes: [condition])
    assert_equal 'and', node.combinator
    assert_equal 1, node.nodes.length
  end

  test 'type is :group' do
    node = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'or', nodes: [])
    assert_equal :group, node.type
  end

  test 'defaults combinator to and' do
    node = AdvancedSearch::V2::Tree::GroupNode.new(nodes: [])
    assert_equal 'and', node.combinator
  end

  test 'nodes can contain both conditions and sub-groups' do
    sub = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'or', nodes: [condition])
    root = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'and', nodes: [condition, sub])
    assert_equal 2, root.nodes.length
    assert_equal :group, root.nodes.last.type
  end

  test 'defaults nodes to empty array' do
    node = AdvancedSearch::V2::Tree::GroupNode.new
    assert_equal [], node.nodes
  end

  test 'stores or combinator' do
    node = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'or', nodes: [])
    assert_equal 'or', node.combinator
  end

  test 'deeply nested groups preserve structure' do
    leaf = condition
    inner = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'and', nodes: [leaf])
    outer = AdvancedSearch::V2::Tree::GroupNode.new(combinator: 'or', nodes: [inner])
    assert_equal :group, outer.nodes.first.type
    assert_equal :condition, outer.nodes.first.nodes.first.type
  end
end
