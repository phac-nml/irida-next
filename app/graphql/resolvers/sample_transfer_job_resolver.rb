# frozen_string_literal: true

module Resolvers
  # Sample Transfer Job Resolver
  class SampleTransferJobResolver < BaseResolver
    argument :job_id, GraphQL::Types::ID,
             required: true,
             description: 'ID of the transfer job.'

    type Types::SampleTransferJobType, null: true

    def resolve(job_id:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @job_id = job_id
      db_record = GoodJob::Job.find_by(active_job_id: job_id)

      if db_record.blank?
        return {
          samples: nil,
          status: nil,
          errors: [{ path: ['job_id'], message: 'Transfer job not found by provided ID' }]
        }
      end

      job_args = db_record.active_job.arguments
      job_arg_namespace = job_args[0]
      job_arg_user = job_args[1]
      @new_project_id = job_args[2]
      @sample_ids = job_args[3]

      if job_arg_user != current_user
        return {
          samples: nil,
          status: nil,
          errors: [{ path: ['job_id'], message: 'Current user is not the owner of the transfer job' }]
        }
      end

      status = db_record.status

      if status == :error # TODO: add a more complete error message for this, :error may be the incorrect symbol for this
        return {
          samples: nil,
          status:,
          errors: [{ path: ['job_id'], message: 'Transfer job failed. Please contact an administrator.' }]
        }
      elsif status != :succeeded
        return {
          samples: nil,
          status:,
          errors: []
        }
      end

      @service = Samples::TransferService.new(job_arg_namespace, current_user)

      @service.add_transfer_errors(@sample_ids, transferred_sample_ids, @new_project_id)

      if transferred_sample_ids.empty? # rubocop:disable Style/ConditionalAssignment
        samples = nil
      else
        # add the prefix to sample_ids
        samples = transferred_sample_ids.map do |sample_id|
          URI::GID.build(app: GlobalID.app, model_name: Sample.name, model_id: sample_id).to_s
        end
      end

      user_errors = []
      if job_arg_namespace.errors.any?
        user_errors = job_arg_namespace.errors.map do |error|
          {
            path: ['samples', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end

      {
        samples:,
        errors: user_errors,
        status: status
      }
    end

    # TODO: this is duplicate code frm the transfer job
    def grouped_transferred_samples
      @grouped_transferred_samples ||= @service.find_transferred_samples_with_log_data_group_by_project(
        @sample_ids, @new_project_id, @job_id
      )
    end

    def transferred_sample_ids
      return [] if grouped_transferred_samples.empty?

      grouped_transferred_samples.values.flatten.map(&:id)
    end
  end
end
