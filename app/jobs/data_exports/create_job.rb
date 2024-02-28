# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob
    queue_as :default

    def perform(data_export)
      # TODO
    end
  end
end
