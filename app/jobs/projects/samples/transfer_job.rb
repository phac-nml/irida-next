# frozen_string_literal: true

module Projects
  module Samples
    # Job used to transfer samples
    class TransferJob < ApplicationJob
      queue_as :default
      queue_with_priority 15

      def perform(project, current_user, new_project_id, sample_ids, broadcast_target) # rubocop:disable Metrics/MethodLength
        @transferred_sample_ids = Projects::Samples::TransferService.new(
          project, current_user
        ).execute(
          new_project_id,
          sample_ids,
          Flipper.enabled?(:progress_bars) ? broadcast_target : nil
        )

        if project.errors.empty?
          Turbo::StreamsChannel.broadcast_replace_to(
            broadcast_target,
            target: 'transfer_samples_dialog_content',
            partial: 'shared/samples/success',
            locals: {
              type: :success,
              message: I18n.t('projects.samples.transfers.create.success')
            }
          )
        elsif project.errors.include?(:samples)
          errors = project.errors.messages_for(:samples)
          Turbo::StreamsChannel.broadcast_replace_to(
            broadcast_target,
            target: 'transfer_samples_dialog_content',
            partial: 'shared/samples/errors',
            locals: {
              type: :alert,
              message: I18n.t('projects.samples.transfers.create.error'),
              errors: errors
            }
          )
        else
          errors = project.errors.full_messages_for(:base)
          Turbo::StreamsChannel.broadcast_replace_to(
            broadcast_target,
            target: 'transfer_samples_dialog_content',
            partial: 'shared/samples/errors',
            locals: {
              type: :alert,
              message: I18n.t('projects.samples.transfers.create.no_samples_transferred_error'),
              errors: errors
            }
          )
        end
      end
    end
  end
end
