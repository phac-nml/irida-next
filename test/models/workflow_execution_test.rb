# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionTest < ActiveSupport::TestCase
  def setup
    @workflow_execution_valid = workflow_executions(:workflow_execution_valid)
  end

  test 'workflow execution has a namespace_id' do
    assert_not_nil @workflow_execution_valid.namespace_id
    assert_equal projects(:project1).namespace.id, @workflow_execution_valid.namespace_id
  end

  test 'workflow execution with an invalid namespace_id' do
    @workflow_execution_invalid_namespace = WorkflowExecution.new(
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      workflow_engine: 'nextflow',
      workflow_engine_version: '24.10.3',
      metadata: { pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.3' },
      workflow_params: { 'assembler' => 'stub' },
      workflow_engine_parameters: { '-r' => 'dev' },
      workflow_url: 'my_workflow_url',
      run_id: 'my_run_id',
      submitter_id: users(:john_doe).id,
      namespace_id: namespaces_user_namespaces(:john_doe_namespace).id,
      name: 'Invalid Namespace Workflow Execution'
    )

    assert_not @workflow_execution_invalid_namespace.valid?
    assert_not_nil @workflow_execution_invalid_namespace.errors[:namespace]
    assert_includes @workflow_execution_invalid_namespace.errors[:namespace],
                    I18n.t('activerecord.errors.models.workflow_execution.invalid_namespace')
  end

  test 'workflow execution with an missing namespace' do
    @workflow_execution_missing_namespace = WorkflowExecution.new(
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      workflow_engine: 'nextflow',
      workflow_engine_version: '24.10.3',
      metadata: { pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.3' },
      workflow_params: { 'assembler' => 'stub' },
      workflow_engine_parameters: { '-r' => 'dev' },
      workflow_url: 'my_workflow_url',
      run_id: 'my_run_id',
      submitter_id: users(:steve_doe).id,
      namespace_id: 'This namespace has been deleted',
      name: 'Invalid Namespace Workflow Execution'
    )

    assert_not @workflow_execution_missing_namespace.valid?
    assert_not_nil @workflow_execution_missing_namespace.errors[:namespace]
    assert_includes @workflow_execution_missing_namespace.errors[:namespace],
                    I18n.t('activerecord.errors.models.workflow_execution.missing_namespace')
  end

  test 'valid workflow execution' do
    assert @workflow_execution_valid.valid?
  end

  test 'invalid workflow execution' do
    @workflow_execution_valid.name = ''
    assert_not @workflow_execution_valid.valid?
  end

  test 'invalid metadata' do
    @workflow_execution_invalid_metadata = WorkflowExecution.new(
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      workflow_engine: 'nextflow',
      workflow_engine_version: '24.10.3',
      metadata: { pipeline_id: 'phac-nml/iridanextexample', 'missing a param here': 'invalid' },
      workflow_params: { 'assembler' => 'stub' },
      workflow_engine_parameters: { '-r' => 'dev' },
      workflow_url: 'my_workflow_url',
      run_id: 'my_run_id',
      submitter_id: users(:john_doe).id,
      namespace_id: namespaces_project_namespaces(:project1_namespace).id,
      name: 'Invalid Metadata Workflow Execution'
    )

    assert_not @workflow_execution_invalid_metadata.valid?
    assert_not_nil @workflow_execution_invalid_metadata.errors[:metadata]
    assert_includes @workflow_execution_invalid_metadata.errors.full_messages,
                    'Metadata object at root is missing required properties: workflow_version'
  end

  test 'invalid workflow specified' do
    @workflow_execution_invalid_workflow = WorkflowExecution.new(
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      workflow_engine: 'nextflow',
      workflow_engine_version: '24.10.3',
      metadata: { pipeline_id: 'wn1', workflow_version: 'invalid' },
      workflow_params: { 'assembler' => 'stub' },
      workflow_engine_parameters: { '-r' => 'dev' },
      workflow_url: 'my_workflow_url',
      run_id: 'my_run_id',
      submitter_id: users(:james_doe).id,
      namespace_id: namespaces_project_namespaces(:project1_namespace).id,
      name: 'Invalid Workflow Workflow Execution'
    )

    assert_not @workflow_execution_invalid_workflow.valid?
    assert_not_nil @workflow_execution_invalid_workflow.errors[:base]
    assert_includes @workflow_execution_invalid_workflow.errors[:base],
                    I18n.t('activerecord.errors.models.workflow_execution.invalid_workflow',
                           pipeline_id: @workflow_execution_invalid_workflow.metadata['pipeline_id'],
                           workflow_version: @workflow_execution_invalid_workflow.metadata['workflow_version'])
  end

  test 'state with type enum using key assignment' do
    @workflow_execution_valid.state = :initial
    assert @workflow_execution_valid.initial?

    @workflow_execution_valid.state = :prepared
    assert_not @workflow_execution_valid.initial?
    assert @workflow_execution_valid.prepared?

    @workflow_execution_valid.state = :submitted
    assert_not @workflow_execution_valid.prepared?
    assert @workflow_execution_valid.submitted?

    @workflow_execution_valid.state = :running
    assert_not @workflow_execution_valid.submitted?
    assert @workflow_execution_valid.running?

    @workflow_execution_valid.state = :completing
    assert_not @workflow_execution_valid.running?
    assert @workflow_execution_valid.completing?

    @workflow_execution_valid.state = :completed
    assert_not @workflow_execution_valid.completing?
    assert @workflow_execution_valid.completed?

    @workflow_execution_valid.state = :error
    assert_not @workflow_execution_valid.completed?
    assert @workflow_execution_valid.error?

    @workflow_execution_valid.state = :canceling
    assert_not @workflow_execution_valid.error?
    assert @workflow_execution_valid.canceling?

    @workflow_execution_valid.state = :canceled
    assert_not @workflow_execution_valid.canceling?
    assert @workflow_execution_valid.canceled?
  end

  test 'state with type enum using int assignment' do
    @workflow_execution_valid.state = 0
    assert @workflow_execution_valid.initial?

    @workflow_execution_valid.state = 1
    assert_not @workflow_execution_valid.initial?
    assert @workflow_execution_valid.prepared?

    @workflow_execution_valid.state = 2
    assert_not @workflow_execution_valid.prepared?
    assert @workflow_execution_valid.submitted?

    @workflow_execution_valid.state = 3
    assert_not @workflow_execution_valid.submitted?
    assert @workflow_execution_valid.running?

    @workflow_execution_valid.state = 4
    assert_not @workflow_execution_valid.running?
    assert @workflow_execution_valid.completing?

    @workflow_execution_valid.state = 5
    assert_not @workflow_execution_valid.completing?
    assert @workflow_execution_valid.completed?

    @workflow_execution_valid.state = 6
    assert_not @workflow_execution_valid.completed?
    assert @workflow_execution_valid.error?

    @workflow_execution_valid.state = 7
    assert_not @workflow_execution_valid.error?
    assert @workflow_execution_valid.canceling?

    @workflow_execution_valid.state = 8
    assert_not @workflow_execution_valid.canceling?
    assert @workflow_execution_valid.canceled?
  end

  test 'cancellable' do
    @workflow_execution_valid.state = :initial
    assert @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :submitted
    assert @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :running
    assert @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :prepared
    assert @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :completing
    assert_not @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :completed
    assert_not @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :error
    assert_not @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :canceling
    assert_not @workflow_execution_valid.cancellable?

    @workflow_execution_valid.state = :canceled
    assert_not @workflow_execution_valid.cancellable?
  end

  test 'deletable' do
    # Test cleaned workflow execution
    @workflow_execution_valid.cleaned = true
    @workflow_execution_valid.state = :completed
    assert @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :error
    assert @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :canceled
    assert @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :initial
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :submitted
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :running
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :prepared
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :completing
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :canceling
    assert_not @workflow_execution_valid.deletable?

    # Test unclean workflow execution
    @workflow_execution_valid.cleaned = false
    @workflow_execution_valid.state = :completed
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :error
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :canceled
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :initial
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :submitted
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :running
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :prepared
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :completing
    assert_not @workflow_execution_valid.deletable?

    @workflow_execution_valid.state = :canceling
    assert_not @workflow_execution_valid.deletable?
  end

  test 'sent_to_ga4gh' do
    @workflow_execution_valid.state = :submitted
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :running
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :completing
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :completed
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :error
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :canceling
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :canceled
    assert @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :prepared
    assert_not @workflow_execution_valid.sent_to_ga4gh?

    @workflow_execution_valid.state = :initial
    assert_not @workflow_execution_valid.sent_to_ga4gh?
  end

  test 'send_email' do
    workflow_execution_example = workflow_executions(:irida_next_example)

    workflow_execution_example.state = :completed
    assert_enqueued_emails 1 do
      workflow_execution_example.save
      assert_enqueued_email_with PipelineMailer, :complete_user_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :error
    assert_enqueued_emails 1 do
      workflow_execution_example.save
      assert_enqueued_email_with PipelineMailer, :complete_user_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :submitted
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :running
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :completing
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :canceling
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :canceled
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :prepared
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    workflow_execution_example.state = :initial
    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end

    assert_enqueued_emails 0 do
      workflow_execution_example.save
    end
  end

  test 'as_wes_params' do
    @workflow_execution_valid['tags']['test_key'] = 'test_value'
    as_wes_params = @workflow_execution_valid.as_wes_params
    assert_equal @workflow_execution_valid['workflow_params'].to_json, as_wes_params[:workflow_params]
    assert_equal @workflow_execution_valid['workflow_engine_parameters'].to_json,
                 as_wes_params[:workflow_engine_parameters]
    assert_equal @workflow_execution_valid['tags'].to_json,
                 as_wes_params[:tags]
    assert_equal @workflow_execution_valid['workflow_type'], as_wes_params[:workflow_type]
    assert_equal @workflow_execution_valid['workflow_type_version'], as_wes_params[:workflow_type_version]
    assert_equal @workflow_execution_valid['workflow_engine'], as_wes_params[:workflow_engine]
    assert_equal @workflow_execution_valid['workflow_engine_version'], as_wes_params[:workflow_engine_version]
    assert_equal @workflow_execution_valid['workflow_url'], as_wes_params[:workflow_url]
  end

  test 'state_timestamp returns nil for invalid state' do
    # Test with a state that doesn't exist in the states enum
    result = @workflow_execution_valid.state_timestamp(:invalid_state)
    assert_nil result
  end

  test 'state_timestamp returns timestamp for valid state' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)
    workflow_execution.create_logidze_snapshot!

    running_state_timestamp = nil

    freeze_time do
      workflow_execution.state = :running
      workflow_execution.save
      workflow_execution.create_logidze_snapshot!
      running_state_timestamp = Time.now.to_i
    end

    # When multiple log entries exist, should return the earliest timestamp for that state
    timestamp = workflow_execution.state_timestamp(:running)

    assert_equal timestamp.to_i, running_state_timestamp
  end

  test 'timestamp_as_bigint constructs proper AREL node' do
    log_entry_table = Arel::Table.new('log_entry')
    arel_node = @workflow_execution_valid.timestamp_as_bigint(log_entry_table)

    # Should return an Arel::Nodes::InfixOperation for casting to bigint
    assert_kind_of Arel::Nodes::InfixOperation, arel_node
  end

  test 'state_log_entry constructs proper WHERE condition' do
    log_entry_table = Arel::Table.new('log_entry')
    state = :prepared

    arel_node = @workflow_execution_valid.state_log_entry(log_entry_table, state)

    # Should return an equality condition
    assert_kind_of Arel::Nodes::Equality, arel_node
  end

  test 'state_log_entry handles all valid states' do
    log_entry_table = Arel::Table.new('log_entry')

    WorkflowExecution.states.each_key do |state|
      arel_node = @workflow_execution_valid.state_log_entry(log_entry_table, state.to_sym)
      assert_kind_of Arel::Nodes::Equality, arel_node, "Failed for state: #{state}"
    end
  end
end
