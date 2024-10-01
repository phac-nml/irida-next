# frozen_string_literal: true

module Groups
  # Service used to Delete Groups
  class DestroyService < BaseService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
      @deleted_samples_count = Project.joins(:namespace).where(namespace: { parent_id: @group.self_and_descendants })
                                      .select(:samples_count).pluck(:samples_count).sum
    end

    def execute
      authorize! @group, to: :destroy?
      group.destroy

      if @group.deleted?
        @group.create_activity key: 'group.destroy',
                               owner: current_user

        return if group.parent.nil?

        @group.parent.create_activity key: 'group.subgroups.destroy',
                                      owner: current_user,
                                      parameters: {
                                        removed_group_puid: @group.puid,
                                        action: 'group_subgroup_destroy'
                                      }

        update_samples_count
      end

      group.update_metadata_summary_by_namespace_deletion
    end

    def update_samples_count
      @group.update_samples_count_by_destroy_service(@deleted_samples_count)
    end
  end
end
