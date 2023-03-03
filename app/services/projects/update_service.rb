# frozen_string_literal: true

module Projects
  # Service used to Update Projects
  class UpdateService < BaseProjectService
    def execute
      namespace_params = params.delete(:namespace_attributes)
      @project.namespace.update(namespace_params)
    end
  end
end
