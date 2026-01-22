# frozen_string_literal: true

# entity class for Sample
class WorkflowExecution < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include MetadataSortable

  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze
  acts_as_paranoid

  broadcasts_refreshes

  after_save :send_email, if: :saved_change_to_state?

  after_commit { broadcast_refresh_later_to [submitter, :workflow_executions] }

  belongs_to :submitter, class_name: 'User'
  belongs_to :namespace
  belongs_to :namespace_with_deleted, -> { with_deleted }, class_name: 'Namespace', foreign_key: :namespace_id # rubocop:disable Rails/InverseOf

  has_many :samples_workflow_executions, dependent: :destroy
  has_many :samples, through: :samples_workflow_executions
  has_many :outputs, dependent: :destroy, class_name: 'Attachment', as: :attachable
  has_many_attached :inputs

  accepts_nested_attributes_for :samples_workflow_executions

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }
  validate :validate_namespace
  validate :validate_workflow_available, if: :initial?
  validates :name, presence: true, if: -> { !submitter.automation_bot? }

  enum :state,
       { initial: 0, prepared: 1, submitted: 2, running: 3, completing: 4, completed: 5, error: 6, canceling: 7,
         canceled: 8 }

  def self.icon
    :terminal_window
  end

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

  def workflow
    Irida::Pipelines.instance.find_pipeline_by(metadata['pipeline_id'], metadata['workflow_version'])
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
    unless namespace
      errors.add(:namespace, I18n.t('activerecord.errors.models.workflow_execution.missing_namespace'))
      return
    end

    return if %w[Group Project].include?(namespace&.type)

    errors.add(:namespace, I18n.t('activerecord.errors.models.workflow_execution.invalid_namespace'))
  end

  def validate_workflow_available
    return unless Irida::Pipelines.instance.find_pipeline_by(metadata['pipeline_id'],
                                                             metadata['workflow_version']).unknown?

    errors.add(:base,
               I18n.t('activerecord.errors.models.workflow_execution.invalid_workflow',
                      pipeline_id: metadata['pipeline_id'],
                      workflow_version: metadata['workflow_version']))
  end

  def state_timestamp(state) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return nil if WorkflowExecution.states[state].nil?

    workflow_executions_table = WorkflowExecution.arel_table
    id_condition = workflow_executions_table[:id].eq(id)

    log_entry_table = Arel::Table.new('log_entry')
    log_entries = Arel::Nodes::Lateral.new(Arel::Nodes::NamedFunction.new(
                                             'jsonb_array_elements',
                                             [Arel::Nodes::InfixOperation.new(
                                               '->',
                                               WorkflowExecution.arel_table[:log_data], Arel::Nodes::Quoted.new('h')
                                             )]
                                           )).as(log_entry_table.name)

    ts_big_int = timestamp_as_bigint(log_entry_table)

    # Timestamp in milliseconds since epoch
    timestamp_ms = Arel::Nodes::NamedFunction.new(
      'trunc', [
        Arel::Nodes::Division.new(ts_big_int, Arel::Nodes::SqlLiteral.new('1000'))
      ]
    )

    workflow_execution_with_log_entries = WorkflowExecution.joins(workflow_executions_table.join(log_entries).on(
      Arel::Nodes::SqlLiteral.new('TRUE')
    ).join_sources)

    workflow_execution_with_log_entries.where(id_condition).where(state_log_entry(
                                                                    log_entry_table, state
                                                                  )).order(ts_big_int.asc).pick(timestamp_ms)
  end

  def timestamp_as_bigint(log_entry)
    Arel::Nodes::InfixOperation.new(
      '::',
      Arel::Nodes::Grouping.new(Arel::Nodes::InfixOperation.new('->>', log_entry, Arel::Nodes::Quoted.new('ts'))),
      Arel::Nodes::SqlLiteral.new('bigint')
    )
  end

  def state_log_entry(log_entry, state)
    # Where condition: (log_entry->'c'->'state')::int = STATE
    Arel::Nodes::InfixOperation.new(
      '::',
      Arel::Nodes::Grouping.new(Arel::Nodes::InfixOperation.new('->',
                                                                Arel::Nodes::InfixOperation.new(
                                                                  '->',
                                                                  log_entry, Arel::Nodes::Quoted.new('c')
                                                                ),
                                                                Arel::Nodes::Quoted.new('state'))),
      Arel::Nodes::SqlLiteral.new('int')
    ).eq(Arel::Nodes::SqlLiteral.new(WorkflowExecution.states[state].to_s))
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
