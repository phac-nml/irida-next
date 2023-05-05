# frozen_string_literal: true

module Projects
  # Service used to Update Projects
  class UpdateService < BaseProjectService
    ProjectUpdateError = Class.new(StandardError)

    def execute
      namespace_params = params.delete(:namespace_attributes)

      action_allowed_for_user(project.namespace, :update?)

      project.namespace.update(namespace_params)
    end
  end
end
