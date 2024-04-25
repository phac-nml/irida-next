# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  def complete_email(workflow_execution)
    @workflow_execution = workflow_execution
    submitter = @workflow_execution.submitter
    I18n.with_locale(submitter.locale) do
      mail(to: submitter.email,
           subject: t(:'mailers.pipeline_mailer.complete_email.subject', id: @workflow_execution.id))
    end
  end

  def error_email(workflow_execution)
    @workflow_execution = workflow_execution
    submitter = @workflow_execution.submitter
    I18n.with_locale(submitter.locale) do
      mail(to: submitter.email,
           subject: t(:'mailers.pipeline_mailer.error_email.subject', id: @workflow_execution.id))
    end
  end
end
