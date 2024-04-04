# frozen_string_literal: true

require 'test_helper'

class PipelineMailerTest < ActionMailer::TestCase
  def test_complete_email
    workflow_execution = workflow_executions(:irida_next_example_completed)
    email = PipelineMailer.complete_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal 'Pipeline completed', email.subject
    assert_match(/i am a pipeline complete email/, email.body.to_s)
  end

  def test_error_email
    workflow_execution = workflow_executions(:irida_next_example_error)
    email = PipelineMailer.error_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal 'Pipeline errored', email.subject
    assert_match(/i am a pipeline error email/, email.body.to_s)
  end
end
