# frozen_string_literal: true

module Samples
  # Service used to clone samples
  class CloneService < BaseProjectService
    CloneError = Class.new(StandardError)

    def execute(new_project_id, sample_ids)
      authorize! @project, to: :clone_sample?

      validate(new_project_id, sample_ids)

      @new_project = Project.find_by(id: new_project_id)
      authorize! @new_project, to: :clone_sample_into_project?

      clone_samples(sample_ids)
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

    def clone_samples(sample_ids) # rubocop:disable Metrics/MethodLength
      cloned_sample_ids = {}

      Sample.public_activity_off

      sample_ids.each do |sample_id|
        sample = Sample.find_by(id: sample_id, project_id: @project.id)
        cloned_sample_id = clone_sample(sample)
        cloned_sample_ids[sample_id] = cloned_sample_id unless cloned_sample_id.nil?
      end

      Sample.public_activity_on

      if cloned_sample_ids.count.positive?
        @project.namespace.create_activity key: 'namespaces_project_namespace.samples.clone', owner: current_user,
                                           parameters:
                                            {
                                              target_project: @new_project.id,
                                              action: 'sample_clone'
                                            }

        @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.cloned_from',
                                               owner: current_user,
                                               parameters:
                                                {
                                                  source_project: @project.id,
                                                  action: 'sample_clone'
                                                }
      end

      cloned_sample_ids
    end

    def clone_sample(sample)
      clone = sample.dup
      clone.project_id = @new_project.id
      clone.generate_puid
      clone.save!

      # update new project metadata sumnmary and then clone attachments to the sample
      @new_project.namespace.update_metadata_summary_by_sample_addition(sample)
      clone_attachments(sample, clone)

      clone.id
    rescue ActiveRecord::RecordInvalid
      @project.errors.add(:sample, I18n.t('services.samples.clone.sample_exists', sample_name: sample.name,
                                                                                  sample_puid: sample.puid))
      nil
    end

    def clone_attachments(sample, clone)
      files = sample.attachments.map { |attachment| attachment.file.blob }
      Attachments::CreateService.new(current_user, clone, { files:, include_activity: false }).execute
    end
  end
end
