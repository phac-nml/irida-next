# frozen_string_literal: true

module Constraints
  # Used to constrain urls that are for projects
  class ProjectUrlConstrainer
    def matches?(request)
      namespace_path = request.params[:namespace_id]
      project_path = request.params[:project_id] || request.params[:id]
      full_path = [namespace_path, project_path].join('/')

      return false unless NamespacePathValidator.valid_path?(full_path)

      Namespaces::ProjectNamespace.find_by_full_path(full_path).present? # rubocop:disable Rails/DynamicFindBy
    end
  end
end
