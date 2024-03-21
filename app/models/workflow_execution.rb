# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze
  acts_as_paranoid

  belongs_to :submitter, class_name: 'User'

  has_many :samples_workflow_executions, dependent: :destroy
  has_many :samples, through: :samples_workflow_executions
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable
  has_many_attached :inputs

  accepts_nested_attributes_for :samples_workflow_executions

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }

  def prepared?
    state == 'prepared'
  end

  def submitted?
    state == 'submitted'
  end

  def completed?
    state == 'completed'
  end

  def finalized?
    state == 'finalized'
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
    %w[running queued prepared new].include?(state)
  end

  def deletable?
    %w[completed error canceled].include?(state)
  end

  def as_wes_params
    {
      workflow_params:,
      workflow_type:,
      workflow_type_version:,
      tags: { createdBy: "#{submitter.first_name} #{submitter.last_name}" },
      workflow_engine:,
      workflow_engine_version:,
      workflow_engine_parameters:,
      workflow_url:
    }.compact
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id run_id state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.metadata_sort(field, dir)
    metadata_field = Arel::Nodes::InfixOperation.new(
      '->',
      WorkflowExecution.arel_table[:metadata],
      Arel::Nodes.build_quoted(URI.decode_www_form_component(field))
    )

    if dir.to_sym == :asc
      metadata_field.asc
    else
      metadata_field.desc
    end
  end
end
