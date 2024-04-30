# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/pipeline_mailer
class PipelineMailerPreview < ActionMailer::Preview
  def complete_user_email
    workflow_execution = WorkflowExecution.first
    workflow_execution.submitter.locale = params[:locale]
    PipelineMailer.complete_user_email(workflow_execution)
  end

  def complete_manager_email
    workflow_execution = WorkflowExecution.first
    namespace = Sample.where(id: workflow_execution.sample_ids).first.project.namespace
    manager_emails = Member.manager_emails(namespace)
    PipelineMailer.complete_manager_email(workflow_execution, manager_emails, params[:locale])
  end

  def error_user_email
    workflow_execution = WorkflowExecution.first
    workflow_execution.submitter.locale = params[:locale]
    PipelineMailer.error_user_email(workflow_execution)
  end

  def error_manager_email
    workflow_execution = WorkflowExecution.first
    namespace = Sample.where(id: workflow_execution.sample_ids).first.project.namespace
    manager_emails = Member.manager_emails(namespace)
    PipelineMailer.error_manager_email(workflow_execution, manager_emails, params[:locale])
  end
end
