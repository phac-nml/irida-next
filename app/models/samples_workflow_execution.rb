# frozen_string_literal: true

# entity class for Sample
class SamplesWorkflowExecution < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :workflow_execution
  belongs_to :sample
  has_many_attached :inputs
end
