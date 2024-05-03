# frozen_string_literal: true

require 'test_helper'

class PipelineMailerTest < ActionMailer::TestCase
  def test_localized_complete_user_email
    I18n.available_locales.each do |locale|
      workflow_execution = workflow_executions(:irida_next_example_completed)
      workflow_execution.submitter.locale = locale
      email = PipelineMailer.complete_user_email(workflow_execution)
      assert_equal [workflow_execution.submitter.email], email.to
      assert_equal I18n.t(:'mailers.pipeline_mailer.complete_user_email.subject', id: workflow_execution.id, locale:),
                   email.subject
      assert_match(/#{I18n.t(:'mailers.pipeline_mailer.complete_user_email.body_html',
                             id: workflow_execution.id, locale:)}/, email.body.to_s)
    end
  end

  def test_localized_complete_manager_email
    I18n.available_locales.each do |locale|
      workflow_execution = workflow_executions(:irida_next_example_completed)
      manager_emails = Member.manager_emails(workflow_execution.namespace, locale)
      email = PipelineMailer.complete_manager_email(workflow_execution, manager_emails, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.pipeline_mailer.complete_manager_email.subject', id: workflow_execution.id,
                                                                                     locale:), email.subject
      assert_match(/#{I18n.t(:'mailers.pipeline_mailer.complete_manager_email.body_html',
                             id: workflow_execution.id, locale:)}/, email.body.to_s)
    end
  end

  def test_localized_error_user_email
    I18n.available_locales.each do |locale|
      workflow_execution = workflow_executions(:irida_next_example_error)
      workflow_execution.submitter.locale = locale
      email = PipelineMailer.error_user_email(workflow_execution)
      assert_equal [workflow_execution.submitter.email], email.to
      assert_equal I18n.t(:'mailers.pipeline_mailer.error_user_email.subject', id: workflow_execution.id, locale:),
                   email.subject
      assert_match(/#{I18n.t(:'mailers.pipeline_mailer.error_user_email.body_html', id: workflow_execution.id,
                                                                                    locale:)}/, email.body.to_s)
    end
  end

  def test_localized_error_manager_email
    I18n.available_locales.each do |locale|
      workflow_execution = workflow_executions(:irida_next_example_error)
      manager_emails = Member.manager_emails(workflow_execution.namespace, locale)
      email = PipelineMailer.error_manager_email(workflow_execution, manager_emails, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.pipeline_mailer.error_manager_email.subject', id: workflow_execution.id, locale:),
                   email.subject
      assert_match(/#{I18n.t(:'mailers.pipeline_mailer.error_manager_email.body_html', id: workflow_execution.id,
                                                                                       locale:)}/, email.body.to_s)
    end
  end
end
