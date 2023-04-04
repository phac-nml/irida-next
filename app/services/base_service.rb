# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end

  def allowed_to_modify_projects_in_namespace?(namespace)
    if namespace.project_namespace? || namespace.group_namespace?
      namespace.owners.include?(current_user)
    elsif namespace.user_namespace?
      namespace.owner == current_user
    else
      namespace.parent.owner == current_user
    end
  end

  def allowed_to_modify_members_in_namespace?(namespace)
    return true if namespace.owners.include?(current_user) || namespace.owner == current_user

    false
  end
end
