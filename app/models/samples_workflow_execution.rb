# frozen_string_literal: true

# entity class for Sample
class SamplesWorkflowExecution < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :workflow_execution
  belongs_to :sample
  has_many_attached :inputs
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable

  # TODO: Re-enable after validator has been rewritten to validate based on samplesheet schema from the pipeline
  # instead of assuming that all fields other than sample are attachemnts
  # validates_with WorkflowExecutionSamplesheetParamsValidator
end
