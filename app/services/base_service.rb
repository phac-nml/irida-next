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
    return true if namespace_owners_include_user?(namespace)
    return true if namespace_parent_owners_include_user?(namespace)

    false
  end

  def allowed_to_modify_members_in_namespace?(namespace)
    return true if namespace.project_namespace? && allowed_to_modify_projects_in_namespace?(namespace)
    return true if namespace.group_namespace? && allowed_to_modify_group?(namespace)

    false
  end

  def allowed_to_modify_group?(group)
    return true if group.parent.nil? && group.owner == current_user
    return true if namespace_owners_include_user?(group)
    return true if Members::GroupMember.where(namespace: group.ancestors, user: current_user,
                                              access_level: Member::AccessLevel::OWNER).order(:access_level).last

    false
  end

  def namespace_owners_include_user?(namespace)
    if (namespace.project_namespace? || namespace.group_namespace?) && namespace.owners&.include?(current_user)
      return true
    end

    false
  end

  def namespace_parent_owners_include_user?(namespace)
    return true if namespace.group_namespace? && Members::GroupMember.where(
      namespace: namespace.ancestors, user: current_user,
      access_level: Member::AccessLevel::OWNER
    ).order(:access_level).last

    return true if namespace.parent&.group_namespace? && Members::GroupMember.where(
      namespace: namespace.parent&.ancestors, user: current_user,
      access_level: Member::AccessLevel::OWNER
    ).order(:access_level).last

    false
  end

  def namespace_owner_is_user?(namespace)
    return true if (namespace.project_namespace? || namespace.user_namespace?) && namespace.owner == current_user
    return true if namespace.parent&.owner == current_user

    false
  end
end
