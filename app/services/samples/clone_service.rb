# frozen_string_literal: true

module Samples
  # Service used to clone samples
  class CloneService < BaseProjectService
    CloneError = Class.new(StandardError)

    def execute(new_project_id, sample_ids, broadcast_target = nil)
      authorize! @project, to: :clone_sample?

      validate(new_project_id, sample_ids)

      @new_project = Project.find_by(id: new_project_id)
      authorize! @new_project, to: :clone_sample_into_project?
      clone_samples(sample_ids, broadcast_target)
    rescue Samples::CloneService::CloneError => e
      @project.errors.add(:base, e.message)
      {}
    end

    private

    def validate(new_project_id, sample_ids)
      raise CloneError, I18n.t('services.samples.clone.empty_new_project_id') if new_project_id.blank?

      raise CloneError, I18n.t('services.samples.clone.empty_sample_ids') if sample_ids.blank?

      return unless @project.id == new_project_id

      raise CloneError, I18n.t('services.samples.clone.same_project')
    end

    def clone_samples(sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cloned_sample_ids = {}
      cloned_sample_puids = {}
      not_found_sample_ids = []
      total_sample_count = sample_ids.count
      sample_ids.each.with_index(1) do |sample_id, index|
        update_progress_bar(index, total_sample_count, broadcast_target)
        sample = Sample.find_by!(id: sample_id, project_id: @project.id)
        cloned_sample = clone_sample(sample)
        cloned_sample_ids[sample_id] = cloned_sample.id unless cloned_sample.nil?
        cloned_sample_puids[sample.puid] = cloned_sample.puid unless cloned_sample.nil?
      rescue ActiveRecord::RecordNotFound
        not_found_sample_ids << sample_id
        next
      end

      unless not_found_sample_ids.empty?
        @project.errors.add(:samples,
                            I18n.t('services.samples.clone.samples_not_found',
                                   sample_ids: not_found_sample_ids.join(', ')))
      end

      update_namespace_attributes(cloned_sample_ids, cloned_sample_puids) if cloned_sample_ids.count.positive?

      cloned_sample_ids
    end

    def clone_sample(sample)
      clone = sample.dup
      clone.project_id = @new_project.id
      clone.generate_puid
      clone.save!

      # update new project metadata summary and then clone attachments to the sample
      @new_project.namespace.update_metadata_summary_by_sample_addition(sample)
      clone_attachments(sample, clone)

      clone
    rescue ActiveRecord::RecordInvalid
      @project.errors.add(:samples, I18n.t('services.samples.clone.sample_exists', sample_name: sample.name,
                                                                                   sample_puid: sample.puid))
      nil
    end

    def clone_attachments(sample, clone)
      files = sample.attachments.map { |attachment| attachment.file.blob }
      Attachments::CreateService.new(current_user, clone, { files:, include_activity: false }).execute
    end

    def update_samples_count(cloned_samples_count)
      @new_project.parent.update_samples_count_by_addition_services(cloned_samples_count)
    end

    def update_namespace_attributes(cloned_sample_ids, cloned_sample_puids)
      update_samples_count(cloned_sample_ids.count) if @new_project.parent.type == 'Group'

      create_activities(cloned_sample_ids, cloned_sample_puids)
    end

    def create_activities(cloned_sample_ids, cloned_sample_puids) # rubocop:disable Metrics/MethodLength
      @project.namespace.create_activity key: 'namespaces_project_namespace.samples.clone',
                                         owner: current_user,
                                         parameters:
                                          {
                                            target_project_puid: @new_project.puid,
                                            target_project: @new_project.id,
                                            cloned_samples_ids: cloned_sample_ids,
                                            cloned_samples_puids: cloned_sample_puids,
                                            action: 'sample_clone'
                                          }

      @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.cloned_from',
                                             owner: current_user,
                                             parameters:
                                              {
                                                source_project_puid: @project.puid,
                                                source_project: @project.id,
                                                cloned_samples_ids: cloned_sample_ids,
                                                cloned_samples_puids: cloned_sample_puids,
                                                action: 'sample_clone'
                                              }
    end
  end
end
