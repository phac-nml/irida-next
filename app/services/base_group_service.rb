# frozen_string_literal: true

# Base root class for service related classes, scoped by group
class BaseGroupService < BaseService
  attr_accessor :group

  def initialize(group, user = nil, params = {})
    super(user, params.except(:group, :group_id))
    @group = group
  end

  def update_descendants_to_public
    descendants_to_update = @group.self_and_descendants_of_type(
      [Group.sti_name,
       Namespaces::ProjectNamespace.sti_name]
    ).where(public: false).order(type: :asc)

    descendants_to_update.each do |descendant|
      next if descendant.public == true

      descendant.update!(public: true)

      key = descendant.is_a?(Group) ? 'group.update' : 'namespaces_project_namespace.update'

      descendant.create_activity key: key,
                                 owner: Current.user
    end
  end

  def update_descendants_to_private
    descendants_to_update = @group.self_and_descendants_of_type(
      [Group.sti_name,
       Namespaces::ProjectNamespace.sti_name]
    ).where(public: true).order(type: :asc)

    descendants_to_update.each do |descendant|
      next if descendant.public == false

      descendant.update(public: false)

      key = descendant.is_a?(Group) ? 'group.update' : 'namespaces_project_namespace.update'

      descendant.create_activity key: key,
                                 owner: Current.user
    end
  end
end
