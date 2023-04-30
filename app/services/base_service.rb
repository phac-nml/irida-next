# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end

  def allowed_to_modify_projects_in_namespace?(namespace)
    return true if namespace_owner_is_user?(namespace)

    namespace_owners_include_user?(namespace)
  end

  def allowed_to_modify_members_in_namespace?(namespace)
    return true if namespace.project_namespace? && allowed_to_modify_projects_in_namespace?(namespace)

    namespace.group_namespace? && allowed_to_modify_group?(namespace)
  end

  def allowed_to_modify_group?(group)
    return true if group.parent.nil? && group.owner == current_user

    Member.exists?(namespace: group.self_and_ancestors, user: current_user,
                   access_level: Member::AccessLevel::OWNER)
  end

  def namespace_owners_include_user?(namespace)
    Member.exists?(
      namespace:, user: current_user,
      access_level: Member::AccessLevel::OWNER
    ) || Member.exists?(
      namespace: namespace.parent&.self_and_ancestor_ids, user: current_user,
      access_level: Member::AccessLevel::OWNER
    )
  end

  def namespace_owner_is_user?(namespace)
    return true if (namespace.project_namespace? || namespace.user_namespace?) && namespace.owner == current_user
    return true if namespace.parent&.owner == current_user

    false
  end

  def user_has_namespace_maintainer_access?
    return unless namespace.group_namespace?

    Member.exists?(user: current_user, namespace: namespace.self_and_ancestors,
                   access_level: Member::AccessLevel::MAINTAINER)
  end
end
