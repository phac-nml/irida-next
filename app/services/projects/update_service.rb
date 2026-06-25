# frozen_string_literal: true

module Projects
  # Service used to Update Projects
  class UpdateService < BaseProjectService
    class ProjectUpdateError < StandardError
    end

    def execute
      validate_project_not_archived

      authorize! project.namespace, to: :update?

      namespace_params = params.delete(:namespace_attributes)

      updated = project.namespace.update(namespace_params)

      if updated
        @project.namespace.create_activity key: 'namespaces_project_namespace.update',
                                           owner: current_user
      end

      updated
    rescue Projects::UpdateService::ProjectUpdateError => e
      @project.errors.add(:base, e.message)
      false
    end

    private

    def validate_project_not_archived
      return if @project.namespace.archived_at.blank?

      raise ProjectUpdateError,
            I18n.t('services.projects.update.project_read_only')
    end
  end
end
