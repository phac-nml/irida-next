# frozen_string_literal: true

module Samples
  # Job used to transfer samples
  class TransferJob < ApplicationJob # rubocop:disable Metrics/ClassLength
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

      @pre_transfer_error = false

      pre_transfer_check
      @service.update_progress_bar(5, 100, @broadcast_target)

      run_job_steps

      return_data
    end

    private

    def run_job_steps
      step :transfer_step, start: 0
      @service.update_progress_bar(95, 100, @broadcast_target)
      step :update_metadata_step, start: 0
      step :update_counts_and_activities_step, start: 0
      @service.update_progress_bar(100, 100, @broadcast_target)
      step :collect_errors_and_broadcast_to_turbo_stream_step
    end

    def pre_transfer_check
      @new_project = Project.find_by(id: @new_project_id)
      raise TransferService::TransferError, I18n.t('services.samples.transfer.invalid_new_project') if @new_project.nil?

      @service.authorize_transfer(@new_project, @sample_ids)
    rescue BaseSampleService::BaseError, TransferService::TransferError => e
      @namespace.errors.add(:base, e.message)
      @pre_transfer_error = true
    end

    def transfer_step(step)
      return if @pre_transfer_error

      transferrable_samples = @service.filter_sample_ids(@sample_ids, 'transfer', false)
      project_sample_ids_to_transfer = @service.organize_samples_by_project(transferrable_samples)

      @service.perform_transfer_with_lock(
        @new_project, project_sample_ids_to_transfer, job_id, step
      )
    end

    def update_metadata_step(step)
      return if @pre_transfer_error

      grouped_transferred_samples.sort[step.cursor..]&.each do |previous_project_id, samples|
        @service.update_metadata_summary_counts(
          samples.map(&:id), projects_by_id[previous_project_id], @new_project
        )

        step.advance!
      end
    end

    def update_counts_and_activities_step(step)
      return if @pre_transfer_error

      grouped_transferred_samples.sort[step.cursor..]&.each do |previous_project_id, samples|
        @service.update_samples_count_and_create_activities(
          samples, projects_by_id[previous_project_id], @new_project
        )

        step.advance!
      end
    end

    def collect_errors_and_broadcast_to_turbo_stream_step # rubocop:disable Metrics/MethodLength
      @service.add_transfer_errors(@sample_ids, transferred_sample_ids, @new_project_id) unless @pre_transfer_error

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
      return [] if @pre_transfer_error

      transferred_sample_ids
    end

    def grouped_transferred_samples
      @grouped_transferred_samples ||= @service.find_transferred_samples_with_log_data_group_by_project(
        @sample_ids, @new_project_id, job_id
      )
    end

    def transferred_sample_ids
      return [] if grouped_transferred_samples.empty?

      grouped_transferred_samples.values.flatten.map(&:id)
    end

    def projects_by_id
      @projects_by_id ||= Project.where(id: grouped_transferred_samples.keys).index_by(&:id)
    end
  end
end
