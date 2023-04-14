# frozen_string_literal: true

module Projects
  # Service used to Update Projects
  class UpdateService < BaseProjectService
    ProjectUpdateError = Class.new(StandardError)

    def execute
      namespace_params = params.delete(:namespace_attributes)

      unless allowed_to_modify_projects_in_namespace?(project.namespace)
        raise ProjectUpdateError,
              I18n.t('services.projects.update.no_permission')
      end

      project.namespace.update(namespace_params)
    rescue Projects::UpdateService::ProjectUpdateError => e
      project.errors.add(:base, e.message)
      false
    end
  end
end
