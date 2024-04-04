# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/pipeline_mailer
class PipelineMailerPreview < ActionMailer::Preview
  def complete_email
    workflow_execution = WorkflowExecution.where("metadata ->> 'workflow_name' = ?", 'irida-next-example').first
    PipelineMailer.complete_email(workflow_execution)
  end

  def error_email
    workflow_execution = WorkflowExecution.where("metadata ->> 'workflow_name' = ?", 'irida-next-example').first
    PipelineMailer.error_email(workflow_execution)
  end
end
