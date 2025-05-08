# frozen_string_literal: true

# Helper for namespace paths
module NamespacePathHelper
  def namespace_path(namespace)
    if namespace.group_namespace?
      group_path(namespace)
    elsif namespace.project_namespace?
      namespace_project_path(namespace.parent, namespace.project)
    end
  end
end
