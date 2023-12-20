# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    module V1
      # GA4GH WES API States
      class States
        CANCELATION_STATES = %w[
          CANCELED CANCELING PREEMPTED
        ].freeze

        ERROR_STATES = %w[
          EXECUTOR_ERROR SYSTEM_ERROR
        ].freeze
      end
    end
  end
end
