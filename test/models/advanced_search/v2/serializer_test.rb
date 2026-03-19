# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::SerializerTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  VALID_JSON = <<~JSON
    {
      "version": "2",
      "combinator": "and",
      "nodes": [
        { "type": "condition", "field": "name", "operator": "contains", "value": "ERR" },
        {
          "type": "group",
          "combinator": "or",
          "nodes": [
            { "type": "condition", "field": "created_at", "operator": ">=", "value": "2024-01-01" }
          ]
        }
      ]
    }
  JSON

  test 'parses valid JSON into a GroupNode tree' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    assert_instance_of AdvancedSearch::V2::Tree::GroupNode, tree
    assert_equal 'and', tree.combinator
    assert_equal 2, tree.nodes.length
  end

  test 'parses condition nodes correctly' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    condition = tree.nodes.first
    assert_equal :condition, condition.type
    assert_equal 'name', condition.field
    assert_equal 'contains', condition.operator
    assert_equal 'ERR', condition.value
  end

  test 'parses nested group nodes correctly' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    sub_group = tree.nodes.last
    assert_equal :group, sub_group.type
    assert_equal 'or', sub_group.combinator
    assert_equal 1, sub_group.nodes.length
  end

  test 'returns nil for nil input' do
    assert_nil AdvancedSearch::V2::Serializer.parse(nil)
  end

  test 'returns nil for blank input' do
    assert_nil AdvancedSearch::V2::Serializer.parse('')
  end

  test 'raises on invalid JSON' do
    assert_raises(AdvancedSearch::V2::Serializer::ParseError) do
      AdvancedSearch::V2::Serializer.parse('not json')
    end
  end

  test 'raises ParseError on unknown node type' do
    json = JSON.generate({
                           'version' => '2', 'combinator' => 'and',
                           'nodes' => [{ 'type' => 'unknown', 'field' => 'name' }]
                         })
    assert_raises(AdvancedSearch::V2::Serializer::ParseError) do
      AdvancedSearch::V2::Serializer.parse(json)
    end
  end

  test 'dumps a tree back to JSON string' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    json = AdvancedSearch::V2::Serializer.dump(tree)
    parsed = JSON.parse(json)
    assert_equal '2', parsed['version']
    assert_equal 'and', parsed['combinator']
    assert_equal 2, parsed['nodes'].length
  end

  test 'dump of nil returns nil' do
    assert_nil AdvancedSearch::V2::Serializer.dump(nil)
  end

  test 'round-trips a tree through parse then dump' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    json = AdvancedSearch::V2::Serializer.dump(tree)
    tree2 = AdvancedSearch::V2::Serializer.parse(json)
    assert_equal tree.combinator, tree2.combinator
    assert_equal tree.nodes.length, tree2.nodes.length
    assert_equal tree.nodes.first.field, tree2.nodes.first.field
  end

  test 'dump omits version key from nested groups' do
    tree = AdvancedSearch::V2::Serializer.parse(VALID_JSON)
    json = AdvancedSearch::V2::Serializer.dump(tree)
    parsed = JSON.parse(json)
    nested_group = parsed['nodes'].last
    assert_equal 'or', nested_group['combinator']
    assert_not nested_group.key?('version'), 'nested group should not have version key'
  end

  test 'parses empty nodes array' do
    json = JSON.generate({ 'version' => '2', 'combinator' => 'and', 'nodes' => [] })
    tree = AdvancedSearch::V2::Serializer.parse(json)
    assert_equal [], tree.nodes
  end
end
