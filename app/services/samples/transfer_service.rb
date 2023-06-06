# frozen_string_literal: true

module Samples
  # Service used to Transfer Samples
  class TransferService < BaseProjectService
    TransferError = Class.new(StandardError)

    def execute(sample_transfer)
      @sample_transfer = sample_transfer

      return false unless @sample_transfer

      validate(@sample_transfer)

      # Authorize if user can transfer samples from the current project
      authorize! @project, to: :transfer_sample?

      # Authorize if user can transfer samples to the new project
      @new_project = Project.find_by(id: @sample_transfer.project_id)
      authorize! @new_project, to: :transfer_sample_into_project?

      transfer(@sample_transfer)

      true
    rescue Samples::TransferService::TransferError => e
      sample_transfer.errors.add(:project_id, e.message)
      false
    end

    private

    def validate(sample_transfer)
      @sample_transfer = sample_transfer
      return unless @project.id == @sample_transfer.project_id.to_i

      raise TransferError,
            I18n.t('services.samples.transfer.duplicate_project')
    end

    def transfer(sample_transfer)
      @sample_transfer = sample_transfer
      ActiveRecord::Base.transaction do
        JSON.parse(@sample_transfer.sample_ids.first).each do |sample_id|
          sample = Sample.find_by(id: sample_id)
          sample.update(project_id: @sample_transfer.project_id)
        end
      end
    end
  end
end
