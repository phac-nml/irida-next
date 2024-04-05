# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  def complete_email(workflow_execution)
    mail(to: workflow_execution.submitter.email, subject: 'Pipeline completed')
  end

  def error_email(workflow_execution)
    mail(to: workflow_execution.submitter.email, subject: 'Pipeline errored')
  end
end
