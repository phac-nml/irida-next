# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionTest < ActiveSupport::TestCase
  def setup
    @workflow_execution_valid = workflow_executions(:workflow_execution_valid)
    @workflow_execution_invalid_metadata = workflow_executions(:workflow_execution_invalid_metadata)
  end

  test 'valid workflow execution' do
    assert @workflow_execution_valid.valid?
  end

  test 'invalid metadata' do
    assert_not @workflow_execution_invalid_metadata.valid?
    assert_not_nil @workflow_execution_invalid_metadata.errors[:metadata]
    assert_equal(
      ['Metadata root is missing required keys: workflow_version'],
      @workflow_execution_invalid_metadata.errors.full_messages
    )
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
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :error
    assert_enqueued_emails 1 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :submitted
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :running
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :completing
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :canceling
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :canceled
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :prepared
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
    end

    workflow_execution_example.state = :initial
    assert_enqueued_emails 0 do
      workflow_execution_example.send_email
      assert_enqueued_email_with PipelineMailer, :complete_email, args: [workflow_execution_example]
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
end
