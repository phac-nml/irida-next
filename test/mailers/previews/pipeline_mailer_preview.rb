# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/pipeline_mailer
class PipelineMailerPreview < ActionMailer::Preview
  def complete_email
    workflow_execution = WorkflowExecution.first
    PipelineMailer.complete_email(workflow_execution)
  end

  def error_email
    workflow_execution = WorkflowExecution.first
    PipelineMailer.error_email(workflow_execution)
  end
end
