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

    def share_namespace_with_group?
      return true if Member.can_share_group?(user, record) == true

      details[:name] = record.name
      false
    end

    def unshare_namespace_with_group?
      return true if Member.can_unshare_group?(user, record) == true

      details[:name] = record.name
      false
    end
  end
end
