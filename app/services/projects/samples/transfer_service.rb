# frozen_string_literal: true

module Projects
  module Samples
    # Service used to transfer samples at the project level
    class TransferService < BaseSampleTransferService
      TransferError = Class.new(StandardError)

      def retrieve_sample_transfer_activity_data(old_project_id, _new_project, sample_ids, transferred_samples_data)
        transferred_samples_data[old_project_id] = Sample.where(id: sample_ids).pluck(:name, :puid).map do |name, puid|
          { sample_name: name, sample_puid: puid }
        end
      end
    end
  end
end
