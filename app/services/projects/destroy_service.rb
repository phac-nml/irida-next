# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    class ProjectDestroyError < StandardError
    end

    def execute # rubocop:disable Metrics/AbcSize
      validate_project_not_archived

      authorize! project, to: :destroy?

      deleted_samples_count = @project.samples.size

      project.namespace.destroy!

      create_activities if project.namespace.deleted?

      return unless project.namespace.deleted? && @project.parent.type == 'Group'

      update_samples_count(deleted_samples_count)
      project.namespace.update_metadata_summary_by_namespace_deletion
    rescue Projects::DestroyService::ProjectDestroyError => e
      project.errors.add(:base, e.message)
      project
    end

    def create_activities
      @project.namespace.create_activity key: 'namespaces_project_namespace.destroy',
                                         owner: current_user

      return unless @project.namespace.parent.group_namespace?

      @project.namespace.parent.create_activity key: 'group.projects.destroy',
                                                owner: current_user,
                                                parameters: {
                                                  project_puid: @project.namespace.puid,
                                                  action: 'group_project_destroy'
                                                }
    end

    def update_samples_count(deleted_samples_count)
      @project.parent.update_samples_count_by_destroy_service(deleted_samples_count)
    end

    private

    def validate_project_not_archived
      return if @project.namespace.archived_at.blank?

      raise ProjectDestroyError,
            I18n.t('services.projects.destroy.project_read_only')
    end
  end
end
