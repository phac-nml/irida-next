# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze
  acts_as_paranoid

  belongs_to :submitter, class_name: 'User'

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :samples, through: :samples_workflow_executions

  validates :metadata, presence: true, json: { schema: METADATA_JSON_SCHEMA }
end
