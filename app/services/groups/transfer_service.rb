# frozen_string_literal: true

module Groups
  # Service used to Transfer Groups
  class TransferService < BaseGroupService
    def initialize(group, user = nil, transfer_form = nil)
      super(group, user)
      @transfer_form = transfer_form
    end

    def execute # rubocop:disable Metrics/AbcSize,Naming/PredicateMethod,Metrics/MethodLength
      return false unless @transfer_form.valid?

      new_namespace = @transfer_form.new_parent

      # Authorize if user can transfer group
      authorize! @group, to: :transfer?

      # Authorize if user can transfer group into namespace
      authorize! new_namespace, to: :transfer_into_namespace?

      old_namespace = @group.parent unless @group.parent.nil?

      group_ancestor_member_user_ids = Member.for_namespace_and_ancestors(@group).not_expired.select(:user_id)
      new_namespace_member_ids = Member.for_namespace_and_ancestors(new_namespace).not_expired
                                       .where(user_id: group_ancestor_member_user_ids).select(&:id)

      parameters = update_params(new_namespace)

      ActiveRecord::Base.transaction do
        @group.update(parameters)

        if Flipper.enabled?(:global_groups, current_user)
          if parameters[:public] == true
            update_descendants_to_public
          elsif parameters[:public] == false
            update_descendants_to_private
          end
        end

        create_activities(old_namespace, new_namespace)

        UpdateMembershipsJob.perform_later(new_namespace_member_ids)

        new_namespace.update_metadata_summary_by_namespace_transfer(@group, old_namespace)

        return true
      end
      false
    end

    private

    def update_params(new_namespace)
      params = { parent_id: new_namespace.id }

      if Flipper.enabled?(:global_groups, current_user)
        params[:public] = true if new_namespace.public? && !@group.public?
        params[:public] = false if !new_namespace.public? && @group.public?
      end

      params
    end

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
  end
end
