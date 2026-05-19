# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::Tree::ConditionNodeTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  test 'stores field, operator, value' do
    node = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: 'contains', value: 'ERR')
    assert_equal 'name', node.field
    assert_equal 'contains', node.operator
    assert_equal 'ERR', node.value
  end

  test 'stores array value for in operator' do
    node = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: 'in', value: %w[foo bar])
    assert_equal %w[foo bar], node.value
  end

  test 'type is :condition' do
    node = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: '=', value: 'x')
    assert_equal :condition, node.type
  end

  test 'stores nil value' do
    node = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: 'blank', value: nil)
    assert_nil node.value
  end

  test 'two nodes with same attributes are not the same object' do
    a = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'f', operator: '=', value: 'v')
    b = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'f', operator: '=', value: 'v')
    assert_not_same a, b
  end

  test 'is frozen after initialization' do
    node = AdvancedSearch::V2::Tree::ConditionNode.new(field: 'name', operator: '=', value: 'x')

    assert node.frozen?
  end
end
