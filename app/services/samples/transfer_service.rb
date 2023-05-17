# frozen_string_literal: true

module Samples
  # Service used to Transfer Samples
  class TransferService < BaseService
    def execute(sample_transfer)
      @sample_transfer = sample_transfer

      # @sample_transfer.sample_ids.each do |sample_id|
      #   sample = Sample.find_by(id: sample_id)
      #   sample.update(project_id: @sample_transfer.project_id)
      # end

      Sample.where(id: @sample_transfer.sample_ids).update_all(project_id: @sample_transfer.project_id)

      true
    end
  end
end
