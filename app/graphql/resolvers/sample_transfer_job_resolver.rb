# frozen_string_literal: true

module Resolvers
  # Sample Transfer Job Resolver
  class SampleTransferJobResolver < BaseResolver
    argument :job_id, GraphQL::Types::ID,
             required: true,
             description: 'ID of the transfer job.'

    type Types::SampleTransferJobType, null: true

    def resolve(job_id:)
      db_record = GoodJob::Job.find_by(active_job_id: job_id)

      if db_record.blank?
        return {
          samples: nil,
          status: nil,
          errors: [{ path: ['job_id'], message: 'Transfer job not found by provided ID' }]
        }
      end

      # TODO: Get arguments from job, verify user has permission to view namespace
      job_args = db_record.active_job.arguments
      job_arg_namespace = job_args[0]
      job_arg_user = job_args[1]
      job_arg_target_project_id = job_args[2]
      job_arg_sample_ids = job_args[3]

      if job_arg_user != current_user
        return {
          samples: nil,
          status: nil,
          errors: [{ path: ['job_id'], message: 'Current user is not the owner of the transfer job' }]
        }
      end

      status = db_record.status

      # TODO: add info that would have been in transfer samples mutation response
      {
        samples: nil,
        errors: [],
        status: status
      }
    end
  end
end
