# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/pipeline_mailer
class PipelineMailerPreview < ActionMailer::Preview
  def complete_email
    workflow_execution = WorkflowExecution.where("metadata ->> 'workflow_name' = ?", 'irida-next-example').first
    PipelineMailer.with(workflow_execution:).complete_email
  end

  def error_email
    workflow_execution = WorkflowExecution.where("metadata ->> 'workflow_name' = ?", 'irida-next-example').first
    PipelineMailer.with(workflow_execution:).error_email
  end
end
