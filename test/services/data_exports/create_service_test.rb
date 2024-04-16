# frozen_string_literal: true

require 'test_helper'

module DataExports
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @project1 = projects(:project1)
      @workflow_execution1 = workflow_executions(:workflow_execution_valid)
      @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    end

    test 'create data export with valid sample export params' do
      valid_params = { 'export_type' => 'sample', 'export_parameters' => { 'ids' => [@sample1.id, @sample2.id] } }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'cannot create date export with params missing export_type' do
      invalid_params = { 'export_parameters' => { 'ids' => [@sample1.id, @sample2.id] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with params missing export_parameters' do
      invalid_params = { 'export_type' => 'sample' }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with incorrect export_type param' do
      invalid_params = { 'export_type' => 'invalid', 'export_parameters' => { 'ids' => [@sample1.id, @sample2.id] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with invalid sample id' do
      invalid_params = { 'export_type' => 'sample', 'export_parameters' => { 'ids' => [99_999_999_999_999] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with both valid and invalid sample ids' do
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id, 99_999_999_999_999] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'valid authorization to create sample export' do
      valid_params = { 'export_type' => 'sample', 'export_parameters' => { 'ids' => [@sample1.id, @sample2.id] } }

      assert_authorized_to(:export_sample_data?, @project1, with: ProjectPolicy,
                                                            context: { user: @user }) do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'data export with valid parameters but unauthorized for sample project' do
      valid_params = { 'export_type' => 'sample', 'export_parameters' => { 'ids' => [@sample1.id, @sample2.id] } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        DataExports::CreateService.new(user, valid_params).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :export_sample_data?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.export_sample_data?', name: @project1.name),
                   exception.result.message
    end

    test 'create data export with valid workflow execution export params' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'cannot create data export with invalid workflow execution id' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [99_999_999_999_999] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with more than 1 id' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [@workflow_execution1.id, @workflow_execution2.id] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'cannot create data export with no ids' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [] } }

      assert_no_difference ['DataExport.count'] do
        DataExports::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'valid authorization to create workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }

      assert_authorized_to(:export_workflow_execution_data?, @workflow_execution1, with: WorkflowExecutionPolicy,
                                                                                   context: { user: @user }) do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'data export with valid parameters but unauthorized for workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        DataExports::CreateService.new(user, valid_params).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :export_workflow_execution_data?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.export_workflow_execution_data?',
                          id: @workflow_execution1.id),
                   exception.result.message
    end
  end
end
