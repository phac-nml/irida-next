# frozen_string_literal: true

require 'test_helper'

module WorkflowExecution
  class SearchGroupTest < ActiveSupport::TestCase
    test 'empty? returns true when all conditions are empty' do
      group = WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: '', operator: '', value: ''),
          WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')
        ]
      )
      assert group.empty?
    end

    test 'empty? returns false when one condition is not empty' do
      group = WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: '', operator: '', value: ''),
          WorkflowExecution::SearchCondition.new(field: 'name', operator: '=', value: 'test')
        ]
      )
      assert_not group.empty?
    end

    test 'conditions_attributes= parses nested attributes when creating group' do
      # NOTE: conditions_attributes= is typically called from the AdvancedSearchable concern
      # when creating groups. Direct usage works differently due to ActiveModel::Attributes
      group = WorkflowExecution::SearchGroup.new
      attributes = {
        '0' => { 'field' => 'name', 'operator' => '=', 'value' => 'test' },
        '1' => { 'field' => 'state', 'operator' => 'in', 'value' => %w[completed error] }
      }

      group.conditions_attributes = attributes

      # The instance variable is set correctly
      assert_equal 2, group.instance_variable_get(:@conditions).length
    end

    test 'conditions default to empty array' do
      group = WorkflowExecution::SearchGroup.new
      assert_equal [], group.conditions
    end
  end
end
