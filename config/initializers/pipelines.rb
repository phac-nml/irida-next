# frozen_string_literal: true

require 'irida/pipelines'

Rails.application.config.to_prepare do
  Irida::Pipelines.instance = Irida::Pipelines.new if Irida::Pipelines.instance.nil?
end

Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    Irida::Pipelines.instance.available_pipelines.each_value do |pipeline|
      next unless pipeline.automatable

      automated_workflow = AutomatedWorkflowExecution.find_by(
        "metadata ->> 'workflow_name' = ? and metadata ->> 'workflow_version' = ?", pipeline.name, pipeline.version
      )

      next unless automated_workflow

      automated_workflow.disabled = pipeline.executable ? false : true
      automated_workflow.save
    end
  end
end
