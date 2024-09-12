# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute # rubocop:disable Metrics/AbcSize
      authorize! project, to: :destroy?

      project.namespace.destroy!

      if project.namespace.deleted?
        @project.namespace.create_activity key: 'namespaces_project_namespace.destroy',
                                           owner: current_user
      end

      return unless project.namespace.deleted? && project.namespace.type != Namespaces::UserNamespace.sti_name

      project.namespace.update_metadata_summary_by_namespace_deletion
    end
  end
end
