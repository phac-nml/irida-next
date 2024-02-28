# frozen_string_literal: true

# Queues the data export create job
class DataExportCreateJob < ApplicationJob
  queue_as :default

  def perform(data_export)
    # TODO
  end
end
