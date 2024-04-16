# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  def complete_email(workflow_execution)
    @workflow_execution = workflow_execution
    mail(to: @workflow_execution.submitter.email,
         subject: t(:'mailers.pipeline_mailer.complete_email.subject', id: @workflow_execution.id))
  end

  def error_email(workflow_execution)
    @workflow_execution = workflow_execution
    mail(to: @workflow_execution.submitter.email,
         subject: t(:'mailers.pipeline_mailer.error_email.subject', id: @workflow_execution.id))
  end
end
