# frozen_string_literal: true

# Base policy for member authorization
class MemberPolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    namespace = options[:namespace]

    namespace_ids = if namespace.project_namespace?
                      [namespace.id] + namespace.parent&.self_and_ancestor_ids
                    else
                      namespace.self_and_ancestor_ids
                    end

    relation.where(id: Member.includes(namespace: [:route]).where(namespace_id: namespace_ids)
            .order('routes.path': :desc).select(
              :id, :user_id, :namespace_id
            ).uniq(&:user_id).pluck(:id)) # rubocop:disable Rails/PluckInWhere
  end
end
