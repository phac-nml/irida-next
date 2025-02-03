# frozen_string_literal: true

# Base policy for metadata templates authorization
class MetadataTemplatePolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]

    namespace_ids = if namespace.project_namespace?
                      [namespace.id] + namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    relation.joins(:created_by).where(namespace_id: namespace_ids)
  end
end
