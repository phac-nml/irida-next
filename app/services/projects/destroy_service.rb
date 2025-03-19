# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute # rubocop:disable Metrics/AbcSize
      authorize! project, to: :destroy?

      deleted_samples_count = @project.samples.size

      project.namespace.destroy!

      create_activities if project.namespace.deleted?

      return unless project.namespace.deleted? && project.namespace.type != Namespaces::UserNamespace.sti_name

      return unless @project.parent.type == 'Group'

      update_samples_count(deleted_samples_count) if @project.parent.type == 'Group'
      project.namespace.update_metadata_summary_by_namespace_deletion
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
  end
end
