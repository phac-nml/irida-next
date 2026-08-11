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

  private

  def update_progress_bar(current_count, total_count, broadcast_target)
    return unless broadcast_target.present? && total_count.to_i.positive?

    percentage = (current_count.to_f / total_count * 100).clamp(0, 100)
    dom_id = ProgressBarStream.dom_id_for(broadcast_target)

    Turbo::StreamsChannel.broadcast_replace_to broadcast_target,
                                               partial: 'shared/progress_bar',
                                               locals: { percentage:, dom_id: },
                                               target: dom_id
  end

  def strip_whitespaces(string)
    string.gsub(/\s+/, ' ').strip
  end

  def active_workflow_execution_sample_puids(sample_ids)
    Sample.where(id: sample_ids)
          .joins(:workflow_executions)
          .where(workflow_executions: { state: ACTIVE_WORKFLOW_EXECUTION_STATES })
          .distinct
          .pluck(:puid)
  end
end
