# frozen_string_literal: true

# Helper for namespace row component
module NamespaceRowHelper
  def namespace_row_aria_label(namespace)
    if namespace.group_namespace?
      group_aria_label(namespace)
    elsif namespace.project_namespace?
      project_aria_label(namespace)
    end
  end

  private

  def effective_access_level(namespace)
    t(
      :"members.access_levels.level_#{Member.effective_access_level(namespace, Current.user)}"
    )
  end

  def group_aria_label(namespace)
    t(:'components.treegrid.row.group.aria_label',
      name: namespace.name, puid: namespace.puid,
      role: effective_access_level(namespace),
      subgroups_count: namespace.children.count,
      group_projects_count: namespace.project_namespaces.count,
      samples_count: namespace.aggregated_samples_count)
  end

  def project_aria_label(namespace)
    t(:'components.treegrid.row.project.aria_label',
      name: namespace.name, puid: namespace.puid,
      role: effective_access_level(namespace),
      samples_count: namespace.project.samples.count)
  end
end
