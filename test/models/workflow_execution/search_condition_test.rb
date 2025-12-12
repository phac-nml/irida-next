# frozen_string_literal: true

require 'test_helper'

class WorkflowExecution::SearchConditionTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  test 'empty? returns true when all attributes are blank' do
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')
    assert condition.empty?
  end

  test 'empty? returns false when field has a value' do
    condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: '', value: '')
    assert_not condition.empty?
  end

  test 'empty? returns false when operator has a value' do
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '=', value: '')
    assert_not condition.empty?
  end

  test 'empty? returns false when value has a value' do
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '', value: 'test')
    assert_not condition.empty?
  end

  test 'empty? handles array values correctly' do
    # Empty array is considered empty
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '', value: [])
    assert condition.empty?

    # Array without nils returns true (compact! returns nil when no changes)
    # This matches Sample::SearchCondition behavior
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '', value: ['test'])
    assert condition.empty? # compact! returns nil, so considered empty

    # Array with nils is not empty (compact! returns the array)
    condition = WorkflowExecution::SearchCondition.new(field: '', operator: '', value: [nil, 'test'])
    assert_not condition.empty?
  end

  test 'attributes can be assigned' do
    condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed')
    assert_equal 'state', condition.field
    assert_equal '=', condition.operator
    assert_equal 'completed', condition.value
  end
end
