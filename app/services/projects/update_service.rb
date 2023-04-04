# frozen_string_literal: true

module Projects
  # Service used to Update Projects
  class UpdateService < BaseProjectService
    def execute
      namespace_params = params.delete(:namespace_attributes)

      if project.namespace.owners.include?(current_user)
        @project.namespace.update(namespace_params)
      else
        @project.errors.add(:base, I18n.t('services.projects.update.no_permission'))
      end
    end
  end
end
