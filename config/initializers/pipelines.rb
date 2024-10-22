# frozen_string_literal: true

require 'irida/pipelines'

Rails.application.config.to_prepare do
  Irida::Pipelines.instance = Irida::Pipelines.new if Irida::Pipelines.instance.nil?

  Rails.application.config.after_initialize do
    Irida::Pipelines.instance.available_pipelines.each_value do |pipeline|
      automated_workflows = AutomatedWorkflowExecution.where(
        "metadata ->> 'workflow_name' = ? and metadata ->> 'workflow_version' = ?", pipeline.name, pipeline.version
      )

      automated_workflows.each do |automated_workflow|
        automated_workflow.disabled = pipeline.executable && pipeline.automatable ? false : true
        automated_workflow.save
      end
    end
  end
end
