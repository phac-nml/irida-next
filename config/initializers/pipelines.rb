# frozen_string_literal: true

require 'irida/pipelines'

Rails.application.config.to_prepare do
  pipeline_config_file = if Rails.root.join("config/pipelines/#{Rails.env}.json").exist?
                           "config/pipelines/#{Rails.env}.json"
                         else
                           'config/pipelines/pipelines.json'
                         end
  Irida::Pipelines.instance = Irida::Pipelines.new(pipeline_config_file:) if Irida::Pipelines.instance.nil?
end

Rails.application.config.after_initialize do
  if defined?(Rails::Server) ||
     (Rails.env.test? && ActiveRecord::Base.connection.table_exists?('automated_workflow_executions'))

    AutomatedWorkflowExecution.find_each do |automated_workflow_execution|
      pipeline = Irida::Pipelines.instance.find_pipeline_by(
        automated_workflow_execution.metadata['pipeline_id'],
        automated_workflow_execution.metadata['workflow_version'],
        'automatable'
      )
      automated_workflow_execution.disabled = pipeline ? !pipeline.executable : true
      automated_workflow_execution.save
    end
  end
end
