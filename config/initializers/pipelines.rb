# frozen_string_literal: true

require 'irida/pipelines'

Rails.application.config.to_prepare do
  Irida::Pipelines.instance = Irida::Pipelines.new if Irida::Pipelines.instance.nil?
end

Rails.application.config.after_initialize do
  if defined?(Rails::Server) ||
     (Rails.env.test? && ActiveRecord::Base.connection.table_exists?('automated_workflow_executions'))

    AutomatedWorkflowExecution.find_each do |automated_workflow_exectuion|
      pipeline = Irida::Pipelines.instance.find_pipeline_by(automated_workflow_exectuion.metadata['workflow_name'],
                                                            automated_workflow_exectuion.metadata['workflow_version'],
                                                            'automatable')
      automated_workflow_exectuion.disabled = pipeline ? !pipeline.executable : true
      automated_workflow_exectuion.save
    end
  end
end
