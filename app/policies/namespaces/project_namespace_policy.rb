# frozen_string_literal: true

module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < NamespacePolicy
    def update?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def member_listing?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_view?(user, record) == true

      details[:name] = record.name
      false
    end

    def create_member?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_create?(user, record) == true

      details[:name] = record.name
      false
    end

    def destroy_member?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def update_member?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def link_namespace_with_group?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_link_namespace_to_group?(user, record) == true

      details[:name] = record.name
      false
    end

    def unlink_namespace_with_group?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_unlink_namespace_from_group?(user, record) == true

      details[:name] = record.name
      false
    end

    def update_namespace_with_group_link?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_update_namespace_with_group_link?(user, record) == true

      details[:name] = record.name
      false
    end

    def create_bot_accounts?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def destroy_bot_accounts?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def view_bot_accounts?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def view_bot_personal_access_tokens?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def generate_bot_personal_access_token?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def revoke_bot_personal_access_token?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def create_automated_workflow_execution?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def destroy_automated_workflow_execution?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end

    def update_automated_workflow_execution?
      return true if record.parent.user_namespace? && record.parent.owner == user
      return true if Member.can_modify?(user, record) == true

      details[:name] = record.name
      false
    end
  end
end
