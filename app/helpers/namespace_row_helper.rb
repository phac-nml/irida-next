# frozen_string_literal: true

# Helper for namespace row component
module NamespaceRowHelper
  def namespace_row_aria_label(namespace, presenter: nil)
    presenter ||= NamespaceRowPresenter.new(namespace:, user: Current.user)

    if namespace.group_namespace?
      group_aria_label(namespace, presenter)
    elsif namespace.project_namespace?
      project_aria_label(namespace, presenter)
    end
  end

  private

  def group_aria_label(namespace, presenter)
    t(:'components.treegrid.row.group.aria_label',
      name: namespace.name, puid: namespace.puid,
      role: t(:"members.access_levels.level_#{presenter.access_level}"),
      subgroups_count: presenter.children_count,
      group_projects_count: presenter.project_namespaces_count,
      samples_count: presenter.aggregated_samples_count)
  end

  def project_aria_label(namespace, presenter)
    t(:'components.treegrid.row.project.aria_label',
      name: namespace.name, puid: namespace.puid,
      role: t(:"members.access_levels.level_#{presenter.access_level}"),
      samples_count: presenter.samples_count)
  end
end
