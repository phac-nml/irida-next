# frozen_string_literal: true

# non-database model for workflow metadata
class WorkflowMetadata
  include ActiveModel::Model

  attr_accessor :workflow_name, :workflow_version

  validates :workflow_name, presence: true
  validates :workflow_version, presence: true

  # de-serialize metadata attributes
  def self.load(json)
    obj = new
    unless json.nil?
      attrs = JSON.parse json
      obj.workflow_name = attrs['workflow_name']
      obj.workflow_version = attrs['workflow_version']
    end
    obj
  end

  # serialize metadata attributes
  def self.dump(obj)
    obj&.to_json
  end
end

# Validates serialized metadata
class WorkflowMetadataValidator < ActiveModel::Validator
  def validate(record)
    return if record.metadata.valid?

    record.errors.add :base, 'WorkflowMetadata is invalid.'
  end
end
