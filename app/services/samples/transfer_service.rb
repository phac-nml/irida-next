# frozen_string_literal: true

module Samples
  # Service used to Transfer Samples
  class TransferService < BaseService
    def execute(sample_transfer)
      @sample_transfer = sample_transfer

      ActiveRecord::Base.transaction do
        JSON.parse(@sample_transfer.sample_ids.first).each do |sample_id|
          sample = Sample.find_by(id: sample_id)
          sample.update(project_id: @sample_transfer.project_id)
        end
      end

      true
    end
  end
end
