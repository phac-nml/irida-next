# frozen_string_literal: true

module Groups
  # Service used to Transfer Groups
  class TransferService < BaseGroupService
    def initialize(group, user = nil, transfer_form = nil)
      super(group, user)
      @transfer_form = transfer_form
    end

    def execute # rubocop:disable Metrics/AbcSize
      return false unless @transfer_form.valid?

      new_namespace ||= @transfer_form.new_parent

      # Authorize if user can transfer group
      authorize! @group, to: :transfer?

      # Authorize if user can transfer group into namespace
      authorize! new_namespace, to: :transfer_into_namespace?

      old_namespace = @group.parent unless @group.parent.nil?

      group_ancestor_member_user_ids = Member.for_namespace_and_ancestors(@group).not_expired.select(:user_id)
      new_namespace_member_ids = Member.for_namespace_and_ancestors(new_namespace).not_expired
                                       .where(user_id: group_ancestor_member_user_ids).select(&:id)

      @group.update(parent_id: new_namespace.id)

      create_activities(old_namespace, new_namespace)

      UpdateMembershipsJob.perform_later(new_namespace_member_ids)

      update_samples_count(old_namespace, new_namespace)

      new_namespace.update_metadata_summary_by_namespace_transfer(@group, old_namespace)
    end

    private

    def create_activities(old_namespace, new_namespace) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      if old_namespace && new_namespace

        old_namespace.create_activity key: 'group.transfer_out',
                                      owner: current_user,
                                      parameters:
                                      {
                                        transferred_group_id: @group.id,
                                        transferred_group_puid: @group.puid,
                                        old_namespace: old_namespace.puid,
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        new_namespace.create_activity key: 'group.transfer_in',
                                      owner: current_user,
                                      parameters:
                                      {
                                        transferred_group_id: @group.id,
                                        transferred_group_puid: @group.puid,
                                        old_namespace: old_namespace.puid,
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        @group.create_activity key: 'group.transfer_in',
                               owner: current_user,
                               parameters:
                               {
                                 transferred_group_id: @group.id,
                                 transferred_group_puid: @group.puid,
                                 old_namespace: old_namespace.puid,
                                 new_namespace: new_namespace.puid,
                                 action: 'group_namespace_transfer'
                               }

      elsif new_namespace
        new_namespace.create_activity key: 'group.transfer_in_no_exisiting_namespace',
                                      owner: current_user,
                                      parameters:
                                      {
                                        transferred_group_id: @group.id,
                                        transferred_group_puid: @group.puid,
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        @group.create_activity key: 'group.transfer_in_no_exisiting_namespace',
                               owner: current_user,
                               parameters:
                               {
                                 transferred_group_id: @group.id,
                                 transferred_group_puid: @group.puid,
                                 new_namespace: new_namespace.puid,
                                 action: 'group_namespace_transfer'
                               }
      end
    end

    def update_samples_count(old_namespace, new_namespace)
      transferred_samples_count = Project.joins(:namespace).where(namespace: { parent_id: @group.self_and_descendants })
                                         .select(:samples_count).pluck(:samples_count).sum
      if old_namespace
        old_namespace.update_samples_count_by_transfer_service(new_namespace, transferred_samples_count,
                                                               new_namespace.type)
      elsif new_namespace.type == 'Group'
        new_namespace.update_samples_count_by_addition_services(transferred_samples_count)
      end
    end
  end
end
