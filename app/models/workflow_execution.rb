# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  include MetadataSortable
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  # new is a keyword that cannot be used with enums, so we'll change new to initial and in the translation,
  # translate initial back to new
  WORKFLOW_EXECUTION_STATES = {
    initial: 0,
    prepared: 1,
    submitted: 2,
    running: 3,
    completing: 4,
    completed: 5,
    error: 6,
    canceling: 7,
    canceled: 8
  }.with_indifferent_access.freeze

  has_logidze
  acts_as_paranoid

  after_save :send_email, if: :saved_change_to_state?

  belongs_to :submitter, class_name: 'User'

  has_many :samples_workflow_executions, dependent: :destroy
  has_many :samples, through: :samples_workflow_executions
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable
  has_many_attached :inputs

  accepts_nested_attributes_for :samples_workflow_executions

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }

  enum state: WORKFLOW_EXECUTION_STATES

  def send_email
    return unless email_notification

    if completed?
      PipelineMailer.complete_email(self).deliver_later
    elsif error?
      PipelineMailer.error_email(self).deliver_later
    end
  end

  def cancellable?
    %w[submitted running prepared initial].include?(state)
  end

  def deletable?
    %w[completed error canceled].include?(state)
  end

  def sent_to_ga4gh?
    %w[prepared initial].exclude?(state)
  end

  def as_wes_params
    {
      namespace_id:,
      workflow_params: workflow_params.to_json,
      workflow_type:,
      workflow_type_version:,
      tags: tags.to_json,
      workflow_engine:,
      workflow_engine_version:,
      workflow_engine_parameters: workflow_engine_parameters.to_json,
      workflow_url:
    }.compact
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id run_id state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end
end
