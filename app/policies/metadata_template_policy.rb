# frozen_string_literal: true

# Base policy for metadata templates authorization
class MetadataTemplatePolicy < ApplicationPolicy
  def effective_access_level
    return unless record.instance_of?(MetadataTemplate)

    @access_level ||= Member.effective_access_level(record.namespace, user)
    @access_level
  end

  def destroy_metadata_template?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.namespace.name
    false
  end

  def update_metadata_template?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.namespace.name
    false
  end

  scope_for :relation do |relation, options|
    namespace = options[:namespace]
    include_ancestral_templates = options[:include_ancestral_templates]

    namespace_ids = if include_ancestral_templates
                      ancestor_namespace_ids(namespace)
                    else
                      namespace.id
                    end

    relation.joins(:created_by).where(namespace_id: namespace_ids)
  end

  private

  # Resolve the self-and-ancestor namespace ids for `namespace`. When
  # traversal_ids are available, the namespace's `traversal_ids` column
  # already holds its full root-to-self id chain, so it is returned directly
  # - avoiding the 1-2 extra queries the query-based branch below would
  # otherwise fire (a parent load plus an ancestor lookup for a project
  # namespace). The query-based fallback is kept for namespaces whose
  # traversal_ids have not been backfilled yet.
  def ancestor_namespace_ids(namespace)
    return namespace.traversal_ids if namespace.use_traversal_ids?

    if namespace.project_namespace?
      [namespace.id] + namespace.parent&.self_and_ancestor_ids
    else
      namespace.self_and_ancestor_ids
    end
  end
end
