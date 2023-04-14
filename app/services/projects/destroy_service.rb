# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    ProjectDestroyError = Class.new(StandardError)

    def execute
      unless allowed_to_modify_projects_in_namespace?(project.namespace)
        raise ProjectDestroyError,
              I18n.t('services.projects.destroy.no_permission')
      end

      project.namespace.destroy
    rescue Projects::DestroyService::ProjectDestroyError => e
      project.errors.add(:base, e.message)
      false
    end
  end
end
