# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::TreeValidatorTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  include AdvancedSearch::V2::Tree

  def validator
    AdvancedSearch::V2::TreeValidator.new
  end

  test 'valid tree passes validation' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: 'test')]
    )
    result = validator.validate(tree)
    assert result[:valid]
    assert_empty result[:errors]
  end

  test 'empty group is valid' do
    tree = GroupNode.new(combinator: 'and', nodes: [])
    result = validator.validate(tree)
    assert result[:valid]
    assert_empty result[:errors]
  end

  test 'nil tree fails with root error' do
    result = validator.validate(nil)

    assert_not result[:valid]
    assert_includes result[:errors], { path: 'root', message: 'query tree is required' }
  end

  test 'tree with unknown field fails with field error' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'invalid_field', operator: '=', value: 'test')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('invalid_field') })
  end

  test 'tree with invalid operator for field fails' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '>=', value: 'test')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('>=') || e[:message].include?('operator') })
  end

  test 'condition missing operator fails' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '', value: 'test')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('operator') })
  end

  test 'invalid combinator fails' do
    tree = GroupNode.new(
      combinator: 'xor',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: 'test')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('combinator') })
  end

  test 'in operator with non-array value fails' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: 'in', value: 'not_an_array')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('array') })
  end

  test 'not_in operator with non-array value fails' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: 'not_in', value: 'not_an_array')]
    )
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('array') })
  end

  test 'scalar operator with object value fails' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: { bad: 'value' })]
    )
    result = validator.validate(tree)

    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('scalar value') })
  end

  test 'subgroup nested inside subgroup fails (max depth 2)' do
    deep_group = GroupNode.new(
      combinator: 'or',
      nodes: [
        GroupNode.new(
          combinator: 'and',
          nodes: [ConditionNode.new(field: 'name', operator: '=', value: 'test')]
        )
      ]
    )
    tree = GroupNode.new(combinator: 'and', nodes: [deep_group])
    result = validator.validate(tree)
    assert_not result[:valid]
    assert(result[:errors].any? { |e| e[:message].include?('depth') || e[:message].include?('nesting') })
  end

  test 'sub-group directly under root is valid' do
    sub_group = GroupNode.new(
      combinator: 'or',
      nodes: [ConditionNode.new(field: 'name', operator: '=', value: 'test')]
    )
    tree = GroupNode.new(combinator: 'and', nodes: [sub_group])
    result = validator.validate(tree)
    assert result[:valid]
    assert_empty result[:errors]
  end

  test 'empty subgroup directly under root fails validation' do
    tree = GroupNode.new(
      combinator: 'or',
      nodes: [
        GroupNode.new(combinator: 'or', nodes: []),
        ConditionNode.new(field: 'name', operator: '=', value: 'test')
      ]
    )
    result = validator.validate(tree)

    assert_not result[:valid]
    assert_includes result[:errors], { path: 'root.nodes[0]', message: 'group must contain at least one child node' }
  end

  test 'valid metadata field passes' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'metadata.province', operator: '=', value: 'ON')]
    )
    result = validator.validate(tree)
    assert result[:valid]
  end

  test 'in operator with array value passes' do
    tree = GroupNode.new(
      combinator: 'and',
      nodes: [ConditionNode.new(field: 'name', operator: 'in', value: %w[SampleA SampleB])]
    )
    result = validator.validate(tree)
    assert result[:valid]
  end
end
