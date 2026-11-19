# frozen_string_literal: true

# Presents the data rendered (more than once) in a single namespace treegrid
# row (`NamespaceRow::ContentsComponent`), memoizing values so the same
# association/aggregation isn't queried repeatedly while rendering a row's
# aria label and its visible pills/tooltips.
#
# Works for both `Group` and `Namespaces::ProjectNamespace` namespaces; only
# the methods relevant to the namespace's type are ever called by the view.
class NamespaceRowPresenter
  attr_reader :namespace

  def initialize(namespace:, user:, aggregated_samples_count: nil, samples_count: nil)
    @namespace = namespace
    @user = user
    @aggregated_samples_count = aggregated_samples_count
    @samples_count = samples_count
  end

  # Builds a presenter for every namespace in one batch. Preloads each
  # `Group`'s `children`/`project_namespaces` associations and each
  # `Namespaces::ProjectNamespace`'s `project` association in bulk, and
  # computes `aggregated_samples_count` for all `Group` entries in a single
  # query via `Namespaces::AggregatedSamplesCountsService` - avoiding one (or
  # more) extra queries per row.
  #
  # @param namespaces [Enumerable<Namespace>] the namespaces to present (Groups and/or ProjectNamespaces)
  # @param user [User] the user access levels are computed against
  # @return [Hash{String => NamespaceRowPresenter}] presenters keyed by namespace id
  def self.build_collection(namespaces:, user:)
    namespaces = namespaces.to_a
    preloaded_by_id = preload_associations(namespaces)
    groups = preloaded_by_id.values.grep(Group)
    aggregated_samples_counts = Namespaces::AggregatedSamplesCountsService.new(groups:).execute

    namespaces.to_h do |namespace|
      presenter = new(
        namespace: preloaded_by_id.fetch(namespace.id, namespace),
        user:,
        aggregated_samples_count: aggregated_samples_counts[namespace.id]
      )
      [namespace.id, presenter]
    end
  end

  def self.preload_associations(namespaces)
    preloaded_groups(namespaces).merge(preloaded_project_namespaces(namespaces))
  end
  private_class_method :preload_associations

  # Includes `:parent` in both preload queries below: `access_level`
  # (`Member.effective_access_level`) and, for project namespaces,
  # `namespace_path` both read `namespace.parent` - without preloading it,
  # the row's `parent` association would be loaded a second time here
  # (once on this preloaded copy, once on the original object the view
  # iterates), issuing a redundant query per row.
  def self.preloaded_groups(namespaces)
    group_ids = namespaces.filter_map { |namespace| namespace.id if namespace.is_a?(Group) }
    return {} if group_ids.empty?

    Group.where(id: group_ids).includes(:parent, :children, :project_namespaces).index_by(&:id)
  end
  private_class_method :preloaded_groups

  def self.preloaded_project_namespaces(namespaces)
    project_namespace_ids = namespaces.filter_map do |namespace|
      namespace.id if namespace.is_a?(Namespaces::ProjectNamespace)
    end
    return {} if project_namespace_ids.empty?

    Namespaces::ProjectNamespace.where(id: project_namespace_ids).includes(:parent, :project).index_by(&:id)
  end
  private_class_method :preloaded_project_namespaces

  def access_level
    @access_level ||= Member.effective_access_level(namespace, @user)
  end

  def children_count
    @children_count ||= namespace.children.size
  end

  def project_namespaces_count
    @project_namespaces_count ||= namespace.project_namespaces.size
  end

  def aggregated_samples_count
    @aggregated_samples_count ||= namespace.aggregated_samples_count
  end

  def expandable?
    children_count.positive?
  end

  # Sample count for a `Namespaces::ProjectNamespace`. Reads the `Project#samples_count`
  # counter cache column directly instead of `project.samples.size`/`.count`, which avoids
  # an extra query entirely (no bulk service needed for this one).
  def samples_count
    @samples_count ||= namespace.project.samples_count
  end
end
