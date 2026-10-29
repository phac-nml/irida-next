# frozen_string_literal: true

# entity class for Automated Workflow Executions
class AutomatedWorkflowExecution < ApplicationRecord
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze

  belongs_to :namespace
  belongs_to :created_by, class_name: 'User'

  belongs_to :project_namespace, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }

  validate :validate_namespace_type
  validate :validate_required_workflow_params

  def self.icon
    :terminal_window
  end

  def workflow
    Irida::Pipelines.instance.find_pipeline_by(metadata['pipeline_id'], metadata['workflow_version'])
  end

  private

  def validate_namespace_type
    # Only Projects should have automated workflow executions
    return if %w[Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have automated workflow executions')
  end

  # Catch missing required params on save, otherwise every launch of this automated workflow would be rejected
  def validate_required_workflow_params
    return if metadata.blank?

    pipeline = workflow
    return if pipeline.nil? || pipeline.unknown?

    Irida::Nextflow::RequiredWorkflowParams.new(pipeline.workflow_params).missing(workflow_params).each do |name|
      errors.add(:base, I18n.t('workflow_executions.create.required_workflow_param_blank', property: name))
    end
  end
end
