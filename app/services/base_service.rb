# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end

  def allowed_to_modify_projects_in_namespace?(namespace)
    return true if namespace.owner == current_user
    return true if namespace.project_namespace? && namespace.owners.include?(current_user)
    return true if namespace.parent&.owner == current_user

    false
  end

  def allowed_to_modify_members_in_namespace?(namespace)
    return true if namespace.project_namespace? && allowed_to_modify_projects_in_namespace?(namespace)
    return true if namespace.group_namespace? && allowed_to_modify_group?(namespace)

    false
  end

  def allowed_to_modify_group?(group)
    return true if Members::GroupMember.where(namespace: group.ancestors, user: current_user,
                                              access_level: Member::AccessLevel::OWNER).order(:access_level).last
    return true if group.parent.nil? && group.owner == current_user
    return true if group.owners&.include?(current_user)

    false
  end
end
