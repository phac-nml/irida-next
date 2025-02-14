# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord
  include MetadataSortable
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze
  acts_as_paranoid

  broadcasts_refreshes

  after_save :send_email, if: :saved_change_to_state?

  after_commit { broadcast_refresh_to [submitter, :workflow_executions] }

  belongs_to :submitter, class_name: 'User'
  belongs_to :namespace

  has_many :samples_workflow_executions, dependent: :destroy
  has_many :samples, through: :samples_workflow_executions
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable
  has_many_attached :inputs

  accepts_nested_attributes_for :samples_workflow_executions

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }
  validate :validate_namespace
  validate :validate_workflow_available, if: :initial?

  enum :state, %i[initial prepared submitted running completing completed error canceling canceled]

  def send_email
    return unless email_notification

    if submitter.human?
      send_user_emails
    else
      send_manager_emails
    end
  end

  def cancellable?
    %w[submitted running prepared initial].include?(state)
  end

  def deletable?
    %w[completed error canceled].include?(state) && cleaned?
  end

  def sent_to_ga4gh?
    %w[prepared initial].exclude?(state)
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

  ransacker :id do
    Arel.sql('id::varchar')
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name run_id state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def validate_namespace
    return if %w[Group Project].include?(namespace.type)

    errors.add(:namespace, I18n.t('activerecord.errors.models.workflow_execution.invalid_namespace'))
  end

  def validate_workflow_available
    return if Irida::Pipelines.instance.find_pipeline_by(metadata['workflow_name'], metadata['workflow_version'],
                                                         'available').present?

    errors.add(:base,
               I18n.t('activerecord.errors.models.workflow_execution.invalid_workflow',
                      workflow_name: metadata['workflow_name'],
                      workflow_version: metadata['workflow_version']))
  end

  private

  def send_user_emails
    if completed?
      PipelineMailer.complete_user_email(self).deliver_later
    elsif error?
      PipelineMailer.error_user_email(self).deliver_later
    end
  end

  def send_manager_emails
    I18n.available_locales.each do |locale|
      manager_emails = Member.manager_emails(namespace, locale)
      unless manager_emails.empty?
        if completed?
          PipelineMailer.complete_manager_email(self, manager_emails, locale).deliver_later
        elsif error?
          PipelineMailer.error_manager_email(self, manager_emails, locale).deliver_later
        end
      end
    end
  end
end
