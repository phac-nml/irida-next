# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  include MetadataSortable
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

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

  def send_email
    return unless email_notification

    if completed?
      PipelineMailer.complete_email(self).deliver_later
    elsif error?
      PipelineMailer.error_email(self).deliver_later
    end
  end

  def prepared?
    state == 'prepared'
  end

  def submitted?
    state == 'submitted'
  end

  def completing?
    state == 'completing'
  end

  def completed?
    state == 'completed'
  end

  def error?
    state == 'error'
  end

  def canceling?
    state == 'canceling'
  end

  def canceled?
    state == 'canceled'
  end

  def running?
    state == 'running'
  end

  def queued?
    state == 'queued'
  end

  def new?
    state == 'new'
  end

  def cancellable?
    %w[submitted running queued prepared new].include?(state)
  end

  def deletable?
    %w[completed error canceled].include?(state)
  end

  def sent_to_ga4gh?
    %w[prepared new].exclude?(state)
  end

  def as_wes_params
    {
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
