# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :submitter, class_name: 'User'

  serialize :metadata, coder: WorkflowMetadata
  validates_with WorkflowMetadataValidator
end
