# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class TriggerFormTest < ActiveSupport::TestCase
    setup do
      @project = projects(:project1)
      @namespace = groups(:group_one)
      @user = users(:john_doe)
      @request = stub(remote_ip: '127.0.0.1', user_agent: 'test-agent')
      @automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    end

    test 'is invalid when q is blank' do
      form = TriggerForm.new(
        q: nil,
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      assert_not form.valid?
      assert_predicate form.errors[:q], :any?
      # Should have validation error about no search params (not an advanced query)
      assert_includes form.errors[:q].map(&:to_s), 'No search parameters were provided'
    end

    test 'is invalid when query is not an advanced query' do
      # Create a query with empty groups (not advanced)
      form = TriggerForm.new(
        q: { groups_attributes: {} },
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      assert_not form.valid?
      assert_predicate form.errors[:q], :any?
      # Check that the underlying query object is valid but not advanced
      assert form.query_object.valid?
      assert_not form.query_object.advanced_query?
      # Should have specific error about no search parameters
      assert_includes form.errors[:q].map(&:to_s), 'No search parameters were provided'
    end

    test 'is invalid when no samples found' do
      # Create an advanced query that returns no samples
      # Use a valid field with a query that won't match any samples
      q_hash = {
        groups_attributes: {
          '0': {
            conditions_attributes: {
              '0': { field: 'name', operator: '=', value: 'nonexistent_sample_xyz_123' }
            }
          }
        }
      }

      form = TriggerForm.new(
        q: q_hash,
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      assert_not form.valid?
      assert_predicate form.errors[:q], :any?
      # Check that the underlying query object is valid and advanced
      assert form.query_object.valid?
      assert form.query_object.advanced_query?
      # But the form should have error about no samples found
      assert_includes form.errors[:q].map(&:to_s), 'Search did not return any samples to trigger on'
    end

    test 'provides search_group_class' do
      form = TriggerForm.new(
        q: { groups_attributes: {} },
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      assert_equal Sample::SearchGroup, form.search_group_class
    end

    test 'samples method returns query results' do
      # Create an advanced query that returns samples
      q_hash = {
        groups_attributes: {
          '0': {
            conditions_attributes: {
              '0': { field: 'name', operator: '=', value: samples(:sample1).name }
            }
          }
        }
      }

      form = TriggerForm.new(
        q: q_hash,
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      # Even if form is invalid, samples should return query results
      assert_predicate form.samples, :any?
    end

    test 'is valid when advanced query finds samples' do
      # Create an advanced query with a valid sample
      q_hash = {
        groups_attributes: {
          '0': {
            conditions_attributes: {
              '0': { field: 'name', operator: '=', value: samples(:sample1).name }
            }
          }
        }
      }

      form = TriggerForm.new(
        q: q_hash,
        automated_workflow_execution: @automated_workflow_execution,
        project: @project,
        request: @request
      )

      assert form.valid?
      assert form.query_object.valid?
      assert form.query_object.advanced_query?
      assert_predicate form.samples, :any?
    end
  end
end
