# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute
      authorize! project, to: :destroy?

      project.namespace.destroy!

      return unless project.namespace.deleted? && project.namespace.parent.type != 'User'

      project.namespace.update_metadata_summary_by_namespace_deletion
    end
  end
end
