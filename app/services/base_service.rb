# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  include ActionPolicy::Behaviour
  include Irida::Auth

  authorize :user, through: :current_user

  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end

  private

  # rubocop: disable Metrics/ParameterLists
  def stream_progress_update(action, target, content, broadcast_target, index, final_index)
    return unless broadcast_target && ((index % 50).zero? || index == final_index)

    Turbo::StreamsChannel.broadcast_action_to(
      broadcast_target,
      action:,
      target:,
      content:
    )
  end
  # rubocop: enable Metrics/ParameterLists
end
