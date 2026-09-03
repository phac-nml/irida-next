# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  include ActionPolicy::Behaviour
  include Irida::Auth

  ACTIVE_WORKFLOW_EXECUTION_STATES = %w[initial prepared submitted running].freeze

  authorize :user, through: :current_user

  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end

  def update_progress_bar(current_count, total_count, broadcast_target)
    return unless broadcast_target.present? && total_count.to_i.positive?

    percentage = (current_count.to_f / total_count * 100).clamp(0, 100)
    dom_id = ProgressBarStream.dom_id_for(broadcast_target)

    Turbo::StreamsChannel.broadcast_replace_to broadcast_target,
                                               partial: 'shared/progress_bar',
                                               locals: { percentage:, dom_id: },
                                               target: dom_id
  end

  private

  # Validate that samples do not have active workflow executions.
  #
  # Prevents actions on samples that are currently being used in a workflow execution.
  # Active workflow states are: initial, prepared, submitted, running.
  #
  # @param sample_ids [Array<Integer>] IDs of samples to check
  # @param action_type [String] action i18n namespace (e.g., 'transfer', 'destroy')
  # @param error_class [Class] exception class to raise on validation failure
  # @raise [StandardError] if any samples have active workflow executions
  def validate_no_active_workflow_executions_for_action(sample_ids, action_type:, error_class: BaseError)
    active_workflow_sample_puids = active_workflow_execution_sample_puids(sample_ids)

    return if active_workflow_sample_puids.empty?

    raise error_class,
          I18n.t("services.samples.#{action_type}.active_workflow_executions",
                 sample_puids: active_workflow_sample_puids.join(', '))
  end

  def strip_whitespaces(string)
    string.gsub(/\s+/, ' ').strip
  end

  def active_workflow_execution_sample_puids(sample_ids)
    Sample.where(id: sample_ids)
          .joins(samples_workflow_executions: :workflow_execution)
          .where(workflow_executions: { state: ACTIVE_WORKFLOW_EXECUTION_STATES })
          .distinct
          .pluck(:puid)
  end
end
