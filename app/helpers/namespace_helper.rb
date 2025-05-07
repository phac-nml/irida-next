# frozen_string_literal: true

# Helper for namespace paths
module NamespaceHelper
  def namespace_path(namespace)
    if namespace.type == 'Group'
      group_path(namespace)
    elsif namespace.type == 'Project'
      namespace_project_path(namespace.parent, namespace.project)
    end
  end
end
