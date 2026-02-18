# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    module V1
      # GA4GH WES API States
      class States
        CANCELATION_STATES = %w[
          CANCELED CANCELING PREEMPTED
        ].freeze

        SUBMITTED_STATES = %w[
          QUEUED INITIALIZING
        ].freeze

        RUNNING_STATES = %w[
          RUNNING PAUSED
        ].freeze

        ERROR_STATES = %w[
          EXECUTOR_ERROR SYSTEM_ERROR
        ].freeze

        VALID_STATES = (
          CANCELATION_STATES + SUBMITTED_STATES + ERROR_STATES + %w[RUNNING COMPLETE UNKNOWN]
        ).freeze
      end
    end
  end
end
