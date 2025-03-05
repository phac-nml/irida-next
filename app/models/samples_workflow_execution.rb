# frozen_string_literal: true

# entity class for Sample
class SamplesWorkflowExecution < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :workflow_execution
  belongs_to :sample, optional: true
  has_many_attached :inputs
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable

  validates_with WorkflowExecutionSamplesheetParamsValidator
end
