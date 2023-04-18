# frozen_string_literal: true

module Namespaces
  # Policies for project members
  class ProjectNamespacePolicy < ApplicationPolicy
    alias_rule :new?, :create?, :destroy?, to: :allowed_to_modify_project_namespace?

    def index?
      return true if record.owner == user

      Member.exists?(namespace: record.self_and_ancestors, user:)
    end

    def allowed_to_modify_project_namespace?
      return true if record.owner == user

      Member.exists?(namespace: record.self_and_ancestors, user:,
                     access_level: Member::AccessLevel::OWNER)
    end
  end
end
