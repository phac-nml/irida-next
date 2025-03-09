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

  def update_progress_bar(current_count, total_count, broadcast_target)
    return unless broadcast_target

    percentage = current_count.to_f / total_count * 100
    Turbo::StreamsChannel.broadcast_replace_to broadcast_target,
                                               partial: 'shared/progress_bar',
                                               locals: { percentage: },
                                               target: 'progress-bar'
  end
end
