# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  include ActionPolicy::Behaviour
  include Irida::Auth

  authorize :user, through: :current_user

  attr_accessor :current_user, :params

  class BaseError < StandardError
  end

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

  def validate_project_not_archived(obj)
    unless (obj.instance_of?(Sample) && obj.project.namespace.archived_at.present?) ||
           (obj.instance_of?(Namespaces::ProjectNamespace) && obj.archived_at.present?)
      return
    end

    raise BaseError, 'Project is in read-only mode' # I18n.t('services.shared.project_read_only')
  end
end
