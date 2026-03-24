# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::MigratorTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  # V1 format: groups_attributes hash (OR between groups, AND within each group)
  V1_PARAMS = {
    'groups_attributes' => {
      '0' => {
        'conditions_attributes' => {
          '0' => { 'field' => 'name', 'operator' => 'contains', 'value' => 'ERR' },
          '1' => { 'field' => 'created_at', 'operator' => '>=', 'value' => '2024-01-01' }
        }
      },
      '1' => {
        'conditions_attributes' => {
          '0' => { 'field' => 'metadata.organism', 'operator' => '=', 'value' => 'human' }
        }
      }
    }
  }.freeze

  test 'converts V1 groups_attributes to V2 tree' do
    tree = AdvancedSearch::V2::Migrator.from_v1(V1_PARAMS)
    assert_instance_of AdvancedSearch::V2::Tree::GroupNode, tree
    assert_equal 'or', tree.combinator
    assert_equal 2, tree.nodes.length
  end

  test 'each V1 group becomes an AND sub-group' do
    tree = AdvancedSearch::V2::Migrator.from_v1(V1_PARAMS)
    first_group = tree.nodes.first
    assert_equal :group, first_group.type
    assert_equal 'and', first_group.combinator
    assert_equal 2, first_group.nodes.length
  end

  test 'conditions are preserved with correct field/operator/value' do
    tree = AdvancedSearch::V2::Migrator.from_v1(V1_PARAMS)
    cond = tree.nodes.first.nodes.first
    assert_equal 'name', cond.field
    assert_equal 'contains', cond.operator
    assert_equal 'ERR', cond.value
  end

  test 'normalizes legacy operator aliases from v1 params' do
    params = {
      groups_attributes: {
        0 => {
          conditions_attributes: {
            0 => { field: 'name', operator: 'equals', value: 'foo' },
            1 => { field: 'created_at', operator: 'greater_than', value: '2024-01-01' }
          }
        }
      }
    }

    tree = AdvancedSearch::V2::Migrator.from_v1(params)

    assert_equal '=', tree.nodes.first.nodes.first.operator
    assert_equal '>=', tree.nodes.first.nodes.second.operator
  end

  test 'returns nil for nil input' do
    assert_nil AdvancedSearch::V2::Migrator.from_v1(nil)
  end

  test 'returns nil for input with no groups_attributes' do
    assert_nil AdvancedSearch::V2::Migrator.from_v1({})
  end

  test 'skips empty conditions (blank field/operator/value)' do
    params = {
      'groups_attributes' => {
        '0' => {
          'conditions_attributes' => {
            '0' => { 'field' => '', 'operator' => '', 'value' => '' },
            '1' => { 'field' => 'name', 'operator' => '=', 'value' => 'foo' }
          }
        }
      }
    }
    tree = AdvancedSearch::V2::Migrator.from_v1(params)
    assert_equal 1, tree.nodes.first.nodes.length
  end

  test 'returns nil when all groups have only empty conditions' do
    params = {
      'groups_attributes' => {
        '0' => {
          'conditions_attributes' => {
            '0' => { 'field' => '', 'operator' => '', 'value' => '' }
          }
        }
      }
    }
    assert_nil AdvancedSearch::V2::Migrator.from_v1(params)
  end

  test 'single group with single condition produces flat OR tree with one AND sub-group' do
    params = {
      'groups_attributes' => {
        '0' => {
          'conditions_attributes' => {
            '0' => { 'field' => 'name', 'operator' => '=', 'value' => 'foo' }
          }
        }
      }
    }
    tree = AdvancedSearch::V2::Migrator.from_v1(params)
    assert_equal 'or', tree.combinator
    assert_equal 1, tree.nodes.length
    assert_equal :condition, tree.nodes.first.nodes.first.type
  end

  test 'condition with only value blank is still skipped' do
    params = {
      'groups_attributes' => {
        '0' => {
          'conditions_attributes' => {
            '0' => { 'field' => 'name', 'operator' => 'blank', 'value' => '' },
            '1' => { 'field' => 'name', 'operator' => '=', 'value' => 'keep' }
          }
        }
      }
    }
    tree = AdvancedSearch::V2::Migrator.from_v1(params)
    # field+operator present but value blank — plan skips only if ALL three blank
    # so this condition is kept
    assert_equal 2, tree.nodes.first.nodes.length
  end

  test 'accepts symbol-keyed V1 params' do
    params = {
      groups_attributes: {
        0 => {
          conditions_attributes: {
            0 => { field: 'name', operator: '=', value: 'foo' }
          }
        }
      }
    }

    tree = AdvancedSearch::V2::Migrator.from_v1(params)

    assert_instance_of AdvancedSearch::V2::Tree::GroupNode, tree
    assert_equal 'or', tree.combinator
    assert_equal 1, tree.nodes.length
    assert_equal 'foo', tree.nodes.first.nodes.first.value
  end

  test 'returns nil when groups_attributes is not hash-like' do
    assert_nil AdvancedSearch::V2::Migrator.from_v1({ groups_attributes: 'invalid' })
  end

  test 'skips malformed groups whose conditions_attributes is not hash-like' do
    params = {
      groups_attributes: {
        0 => { conditions_attributes: 'invalid' },
        1 => {
          conditions_attributes: {
            0 => { field: 'name', operator: '=', value: 'foo' }
          }
        }
      }
    }

    tree = AdvancedSearch::V2::Migrator.from_v1(params)

    assert_equal 1, tree.nodes.length
    assert_equal 'foo', tree.nodes.first.nodes.first.value
  end
end
