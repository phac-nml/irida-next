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

  def update_progress_bar(percentage, broadcast_target) # rubocop:disable Metrics/MethodLength
    return unless broadcast_target

    Turbo::StreamsChannel.broadcast_action_to(
      broadcast_target,
      action: 'replace',
      target: 'progress-bar',
      content: "<div id='progress-bar'>" \
               "<div class='flex justify-between mb-1'>" \
               "<span class='text-base font-medium text-slate-900 dark:text-white'>" \
               "#{I18n.t('shared.progress_bar.in_progress')}</span>" \
               "<span class='text-sm font-medium text-slate-900 dark:text-white'>#{percentage.ceil}%</span>" \
               '</div>' \
               "<div class='w-full bg-slate-200 rounded-full h-2.5 dark:bg-slate-700'>" \
               "<div class='bg-primary-600 h-2.5 rounded-full' style='width: #{percentage}%' role='progressbar'></div>" \
               '</div>' \
               '</div>'
    )
  end
end
