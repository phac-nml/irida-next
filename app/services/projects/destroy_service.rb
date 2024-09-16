# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute
      authorize! project, to: :destroy?

      project.namespace.destroy!

      create_activities if project.namespace.deleted?

      return unless project.namespace.deleted? && project.namespace.type != Namespaces::UserNamespace.sti_name

      project.namespace.update_metadata_summary_by_namespace_deletion
    end

    def create_activities

      @project.namespace.create_activity key: 'namespaces_project_namespace.destroy',
                                         owner: current_user

      return unless @project.namespace.parent.group_namespace?

      @project.namespace.parent.create_activity key: 'group.projects.destroy',
                                                owner: current_user,
                                                parameters: {
                                                  project_puid: @project.puid
                                                }

    end
  end
end
