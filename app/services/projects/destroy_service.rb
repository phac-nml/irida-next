# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute
      authorize! project, to: :destroy?

      project.namespace.destroy!
    end
  end
end
