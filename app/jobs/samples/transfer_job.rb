# frozen_string_literal: true

module Samples
  # Job used to transfer samples
  class TransferJob < ApplicationJob
    include WithResponsible

    queue_as :default
    queue_with_priority 15

    def perform(namespace, current_user, new_project_id, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength
      @transferred_sample_ids = Samples::TransferService.new(namespace, current_user)
                                                        .execute(
                                                          new_project_id,
                                                          sample_ids,
                                                          Flipper.enabled?(
                                                            :progress_bars
                                                          ) ? broadcast_target : nil
                                                        )

      if namespace.errors.empty?
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'transfer_samples_dialog_content',
          partial: 'shared/samples/success',
          locals: {
            type: :success,
            message: I18n.t('samples.transfers.create.success')
          }
        )
      elsif namespace.errors.include?(:samples)
        errors = namespace.errors.messages_for(:samples)
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'transfer_samples_dialog_content',
          partial: 'shared/samples/errors',
          locals: {
            type: :alert,
            message: I18n.t('samples.transfers.create.error'),
            errors: errors
          }
        )
      else
        errors = namespace.errors.full_messages_for(:base)
        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'transfer_samples_dialog_content',
          partial: 'shared/samples/errors',
          locals: {
            type: :alert,
            message: I18n.t('samples.transfers.create.no_samples_transferred_error'),
            errors: errors
          }
        )
      end
    end
  end
end
