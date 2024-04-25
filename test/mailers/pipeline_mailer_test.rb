# frozen_string_literal: true

require 'test_helper'

class PipelineMailerTest < ActionMailer::TestCase
  def test_complete_email
    workflow_execution = workflow_executions(:irida_next_example_completed)
    email = PipelineMailer.complete_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal I18n.t(:'mailers.pipeline_mailer.complete_email.subject', id: workflow_execution.id), email.subject
    assert_match(/#{I18n.t(:'mailers.pipeline_mailer.complete_email.body_html', id: workflow_execution.id)}/,
                 email.body.to_s)
  end

  def test_error_email
    workflow_execution = workflow_executions(:irida_next_example_error)
    email = PipelineMailer.error_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal I18n.t(:'mailers.pipeline_mailer.error_email.subject', id: workflow_execution.id), email.subject
    assert_match(/#{I18n.t(:'mailers.pipeline_mailer.error_email.body_html', id: workflow_execution.id)}/,
                 email.body.to_s)
  end

  def test_complete_email_in_french
    locale = :fr
    workflow_execution = workflow_executions(:irida_next_example_completed)
    workflow_execution.submitter.locale = locale
    email = PipelineMailer.complete_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal I18n.t(:'mailers.pipeline_mailer.complete_email.subject', id: workflow_execution.id, locale:),
                 email.subject
    assert_match(/#{I18n.t(:'mailers.pipeline_mailer.complete_email.body_html',
                           id: workflow_execution.id, locale:)}/, email.body.to_s)
  end

  def test_error_email_in_french
    locale = :fr
    workflow_execution = workflow_executions(:irida_next_example_error)
    workflow_execution.submitter.locale = locale
    email = PipelineMailer.error_email(workflow_execution)
    assert_equal [workflow_execution.submitter.email], email.to
    assert_equal I18n.t(:'mailers.pipeline_mailer.error_email.subject', id: workflow_execution.id, locale:),
                 email.subject
    assert_match(/#{I18n.t(:'mailers.pipeline_mailer.error_email.body_html', id: workflow_execution.id, locale:)}/,
                 email.body.to_s)
  end
end
