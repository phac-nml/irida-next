# frozen_string_literal: true

module Samples
  # Job used to transfer samples
  class TransferJob < ApplicationJob
    include ActiveJob::Continuable
    include WithResponsible

    queue_as :default
    queue_with_priority 15

    def perform(namespace, current_user, new_project_id, sample_ids, broadcast_target = nil)
      @namespace = namespace
      @current_user = current_user
      @new_project_id = new_project_id
      @sample_ids = sample_ids
      @broadcast_target = broadcast_target
      @service = Samples::TransferService.new(@namespace, @current_user)

      @authorization_error = false

      pre_transfer_check
      @service.update_progress_bar(5, 100, broadcast_target)

      step :transfer_step
      @service.update_progress_bar(95, 100, broadcast_target)
      # step :update_metadata_step
      # step :update_counts_and_activities_step
      @service.update_progress_bar(100, 100, broadcast_target)
      step :collect_errors_and_broadcast_to_turbo_stream_step

      return_data
    end

    private

    def pre_transfer_check
      @new_project = Project.find_by(id: @new_project_id)
      raise TransferService::TransferError, I18n.t('services.samples.transfer.invalid_new_project') if @new_project.nil?

      # authorization check (could be done even on job retry?)
      @service.authorize_transfer(@new_project, @sample_ids)
    rescue BaseSampleService::BaseError, TransferService::TransferError => e
      @namespace.errors.add(:base, e.message)
      @authorization_error = true
    end

    def transfer_step
      return if @authorization_error

      transferrable_samples = @service.filter_sample_ids(@sample_ids, 'transfer', false)
      project_sample_ids_to_transfer = @service.organize_samples_by_project(transferrable_samples)

      # database transactions
      @service.perform_transfer_with_lock(
        @new_project, project_sample_ids_to_transfer, transferrable_samples, job_id
      )
    end

    # def update_metadata_step
    #   return if @authorization_error

    #   transferrable_samples = @service.filter_sample_ids(@sample_ids, 'transfer', false)
    #   project_sample_ids_to_transfer = @service.organize_samples_by_project(transferrable_samples)

    #   transferred_project_sample_ids = @service.build_transferred_project_sample_ids(
    #     project_sample_ids_to_transfer,
    #     @new_project,
    #     transferrable_samples
    #   )

    #   # TODO: needs cursor: each transferred_project_sample_ids.
    #   unless transferred_project_sample_ids.empty?
    #     @service.update_metadata_summary_counts(transferred_project_sample_ids, @new_project)
    #   end
    # end

    # def update_counts_and_activities_step
    #   return if @authorization_error

    #   transferrable_samples = @service.filter_sample_ids(@sample_ids, 'transfer', false)
    #   project_sample_ids_to_transfer = @service.organize_samples_by_project(transferrable_samples)

    #   transferred_project_sample_ids = @service.build_transferred_project_sample_ids(
    #     project_sample_ids_to_transfer,
    #     @new_project,
    #     transferrable_samples
    #   )

    #   # TODO: needs cursor: each transferred_project_sample_ids.
    #   unless transferred_project_sample_ids.empty?
    #     @service.update_samples_count_and_create_activities(transferred_project_sample_ids, @new_project)
    #   end
    # end

    def collect_errors_and_broadcast_to_turbo_stream_step # rubocop:disable Metrics/MethodLength
      @service.add_transfer_errors(@sample_ids, @new_project_id, job_id) unless @authorization_error

      if @namespace.errors.empty?
        Turbo::StreamsChannel.broadcast_replace_to(
          @broadcast_target,
          target: 'transfer_samples_dialog_content',
          partial: 'shared/samples/success',
          locals: {
            type: :success,
            message: I18n.t('samples.transfers.create.success')
          }
        )
      elsif @namespace.errors.include?(:samples)
        errors = @namespace.errors.messages_for(:samples)
        Turbo::StreamsChannel.broadcast_replace_to(
          @broadcast_target,
          target: 'transfer_samples_dialog_content',
          partial: 'shared/samples/errors',
          locals: {
            type: :alert,
            message: I18n.t('samples.transfers.create.error'),
            errors: errors
          }
        )
      else
        errors = @namespace.errors.full_messages_for(:base)
        Turbo::StreamsChannel.broadcast_replace_to(
          @broadcast_target,
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

    def return_data
      return [] if @authorization_error

      transferrable_samples = @service.filter_sample_ids(@sample_ids, 'transfer', false)
      project_sample_ids_to_transfer = @service.organize_samples_by_project(transferrable_samples)

      transferred_project_sample_ids = @service.build_transferred_project_sample_ids(
        project_sample_ids_to_transfer,
        @new_project,
        transferrable_samples
      )

      return [] if transferred_project_sample_ids.empty? || transferred_project_sample_ids.values.all?(&:empty?)

      transferred_project_sample_ids.values.flatten
    end
  end
end
