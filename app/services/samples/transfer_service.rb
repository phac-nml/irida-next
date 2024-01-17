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

      validate_maintainer_sample_transfer if Member.user_has_namespace_maintainer_access?(current_user,
                                                                                          @project.namespace, false)

      transfer(new_project_id, sample_ids)
    rescue Samples::TransferService::TransferError => e
      project.errors.add(:base, e.message)
      []
    end

    private

    def validate(new_project_id, sample_ids)
      raise TransferError, I18n.t('services.samples.transfer.empty_new_project_id') if new_project_id.blank?

      raise TransferError, I18n.t('services.samples.transfer.empty_sample_ids') if sample_ids.blank?

      return unless @project.id == new_project_id.to_i

      raise TransferError,
            I18n.t('services.samples.transfer.same_project')
    end

    def validate_maintainer_sample_transfer
      project_parent_and_ancestors = @project.namespace.parent.self_and_ancestor_ids
      new_project_parent_and_ancestors = @new_project.namespace.parent.self_and_ancestor_ids

      return if project_parent_and_ancestors.intersect?(new_project_parent_and_ancestors)

      raise TransferError,
            I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
    end

    def transfer(new_project_id, sample_ids) # rubocop:disable Metrics/MethodLength
      transferred_samples_ids = []
      not_found_sample_ids = []
      sample_ids.each do |sample_id|
        sample = Sample.find_by(id: sample_id, project_id: @project.id)
        sample.update!(project_id: new_project_id)
        transferred_samples_ids << sample_id
      rescue StandardError
        if sample
          project.errors.add(:samples, I18n.t('services.samples.transfer.sample_exists',
                                              sample_name: sample.name))
        else
          not_found_sample_ids << sample_id
        end
        next
      end
      unless not_found_sample_ids.empty?
        project.errors.add(:samples,
                           I18n.t('services.samples.transfer.samples_not_found',
                                  sample_ids: not_found_sample_ids.join(', ')))
      end
      transferred_samples_ids
    end
  end
end
