# frozen_string_literal: true

module Samples
  # Service used to Transfer Samples
  class TransferService < BaseProjectService
    TransferError = Class.new(StandardError)

    def execute(new_project_id, sample_ids)
      validate(new_project_id, sample_ids)

      # Authorize if user can transfer samples from the current project
      authorize! @project, to: :transfer_sample?

      # Authorize if user can transfer samples to the new project
      @new_project = Project.find_by(id: new_project_id)
      authorize! @new_project, to: :transfer_sample_into_project?

      transfer(new_project_id, sample_ids)
    rescue Samples::TransferService::TransferError => e
      project.errors.add(:base, e.message)
      false
    end

    private

    def validate(new_project_id, sample_ids)
      raise TransferError, I18n.t('services.samples.transfer.empty_new_project_id') if new_project_id.blank?

      raise TransferError, I18n.t('services.samples.transfer.empty_sample_ids') if sample_ids.blank?

      return unless @project.id == new_project_id.to_i

      raise TransferError,
            I18n.t('services.samples.transfer.same_project')
    end

    def transfer(new_project_id, sample_ids)
      has_errors = false
      sample_ids.each do |sample_id|
        sample = Sample.find_by(id: sample_id, project_id: @project.id)
        sample.update!(project_id: new_project_id)
      rescue StandardError => e
        has_errors = true
        project.errors.add(:base, "#{e.message} for sample id  #{sample_id}")
        next
      end
      !has_errors
    end
  end
end
