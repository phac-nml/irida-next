# frozen_string_literal: true

module Resolvers
  # Sample Transfer Job Resolver
  class SampleTransferJobResolver < BaseResolver
    argument :job_id, GraphQL::Types::ID,
             required: true,
             description: 'ID of the transfer job.'

    type Types::SampleTransferJobType, null: true

    TRANSFER_JOB_ARG_KEYS = %i[namespace user new_project_id sample_ids].freeze

    def resolve(job_id:) # rubocop:disable Metrics/MethodLength
      @job_id = job_id
      db_record = GoodJob::Job.find_by(active_job_id: @job_id)

      # Verify job exists
      if db_record.blank?
        return { samples: nil, status: nil, errors: [
          { path: ['job_id'], message: 'Transfer job not found by provided ID' }
        ] }
      end

      # Convert the jobs initial arguments to a hash
      @job_args = TRANSFER_JOB_ARG_KEYS.zip(db_record.active_job.arguments).to_h

      # Auth check
      if @job_args[:user] != current_user
        return { samples: nil, status: nil, errors: [
          { path: ['job_id'], message: 'Current user is not the owner of the transfer job' }
        ] }
      end

      if db_record.finished?
        if db_record.error.present? # Else, job finished successfully, handled below
          return { samples: nil, status: :error, errors: [
            { path: ['job_id'], message: "Transfer job failed with error: #{db_record.error}" }
          ] }
        end
      elsif db_record.locked_at.present?
        return { samples: nil, status: :running, errors: [] }
      else
        return { samples: nil, status: :queued, errors: [] }
      end

      # Happy path: job finished successfully
      { samples: find_transferred_samples, errors: find_errors, status: db_record.status }
    end

    private

    def transferred_sample_ids
      @grouped_transferred_samples ||= transfer_service.find_transferred_samples_with_log_data_group_by_project(
        @job_args[:sample_ids], @job_args[:new_project_id], @job_id
      )
      return [] if @grouped_transferred_samples.empty?

      @grouped_transferred_samples.values.flatten.map(&:id)
    end

    def transfer_service
      @transfer_service ||= Samples::TransferService.new(@job_args[:namespace], current_user)
    end

    def find_transferred_samples
      return nil if transferred_sample_ids.empty?

      # add the prefix to sample_ids
      transferred_sample_ids.map do |sample_id|
        URI::GID.build(app: GlobalID.app, model_name: Sample.name, model_id: sample_id).to_s
      end
    end

    def find_errors
      transfer_service.add_transfer_errors(@job_args[:sample_ids], transferred_sample_ids, @job_args[:new_project_id])

      user_errors = []
      if @job_args[:namespace].errors.any?
        user_errors = @job_args[:namespace].errors.map do |error|
          {
            path: ['samples', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end

      user_errors
    end
  end
end
