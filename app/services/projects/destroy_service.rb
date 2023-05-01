# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    ProjectDestroyError = Class.new(StandardError)

    def execute
      action_allowed_for_user(project.namespace, :destroy?)

      project.namespace.destroy
    rescue Projects::DestroyService::ProjectDestroyError => e
      project.errors.add(:base, e.message)
      false
    end
  end
end
