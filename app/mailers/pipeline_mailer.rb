# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  def complete_user_email(workflow_execution)
    @workflow_execution = workflow_execution
    submitter = @workflow_execution.submitter
    I18n.with_locale(submitter.locale) do
      mail(to: submitter.email,
           subject: t(:'mailers.pipeline_mailer.complete_user_email.subject', id: @workflow_execution.id))
    end
  end

  def complete_manager_email(workflow_execution, manager_emails, locale)
    @workflow_execution = workflow_execution
    I18n.with_locale(locale) do
      mail(bcc: manager_emails,
           subject: t(:'mailers.pipeline_mailer.complete_manager_email.subject', id: @workflow_execution.id))
    end
  end

  def error_user_email(workflow_execution)
    @workflow_execution = workflow_execution
    submitter = @workflow_execution.submitter
    I18n.with_locale(submitter.locale) do
      mail(to: submitter.email,
           subject: t(:'mailers.pipeline_mailer.error_user_email.subject', id: @workflow_execution.id))
    end
  end

  def error_manager_email(workflow_execution, manager_emails, locale)
    @workflow_execution = workflow_execution
    I18n.with_locale(locale) do
      mail(bcc: manager_emails,
           subject: t(:'mailers.pipeline_mailer.error_manager_email.subject', id: @workflow_execution.id))
    end
  end
end
