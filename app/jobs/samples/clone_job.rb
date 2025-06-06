# frozen_string_literal: true

module Samples
  # Job used to clone samples
  class CloneJob < ApplicationJob
    queue_as :default
    queue_with_priority 15

    def perform(namespace, current_user, new_project_id, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      puts 'in job'
      service = if namespace.group_namespace?
                  Groups::Samples::CloneService.new(namespace, current_user)
                else
                  Projects::Samples::CloneService.new(namespace, current_user)
                end
      puts 'start service'
      @cloned_sample_ids = service.execute(
        new_project_id,
        sample_ids,
        Flipper.enabled?(:progress_bars) ? broadcast_target : nil
      )

      if namespace.errors.empty?
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'clone_samples_dialog_content',
          partial: 'shared/samples/success',
          locals: {
            type: :success,
            message: I18n.t('samples.clones.create.success')
          }
        )
      elsif namespace.errors.include?(:samples)
        errors = namespace.errors.messages_for(:samples)
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'clone_samples_dialog_content',
          partial: 'shared/samples/errors',
          locals: {
            type: :alert,
            message: I18n.t('samples.clones.create.error'),
            errors: errors
          }
        )
      else
        errors = namespace.errors.full_messages_for(:base)
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'clone_samples_dialog_content',
          partial: 'shared/samples/errors',
          locals: {
            type: :alert,
            message: I18n.t('samples.clones.create.no_samples_cloned_error'),
            errors: errors
          }
        )
      end
    end
  end
end
