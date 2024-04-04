# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  before_action { @workflow_execution = params[:workflow_execution] }

  def complete_email
    mail(to: @workflow_execution.submitter.email, subject: 'Pipeline completed')
  end

  def error_email
    mail(to: @workflow_execution.submitter.email, subject: 'Pipeline errored')
  end
end
