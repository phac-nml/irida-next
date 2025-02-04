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

    namespace_ids = if namespace.project_namespace?
                      [namespace.id] + namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    relation.joins(:created_by).where(namespace_id: namespace_ids)
  end
end
