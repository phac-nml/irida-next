# frozen_string_literal: true

module Groups
  # Service used to Transfer Groups
  class TransferService < BaseGroupService
    TransferError = Class.new(StandardError)

    def execute(new_namespace) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      validate(new_namespace)

      # Authorize if user can transfer group
      authorize! @group, to: :transfer?

      # Authorize if user can transfer group into namespace
      authorize! new_namespace, to: :transfer_into_namespace?

      old_namespace = @group.parent unless @group.parent.nil?

      if Group.where(parent_id: new_namespace.id).exists?(['path = ? or name = ?', @group.path,
                                                           @group.name])
        raise TransferError, I18n.t('services.groups.transfer.namespace_group_exists')
      end

      group_ancestor_member_user_ids = Member.for_namespace_and_ancestors(@group).not_expired.select(:user_id)
      new_namespace_member_ids = Member.for_namespace_and_ancestors(new_namespace).not_expired
                                       .where(user_id: group_ancestor_member_user_ids).select(&:id)

      @group.update(parent_id: new_namespace.id)

      create_activities(old_namespace, new_namespace)

      UpdateMembershipsJob.perform_later(new_namespace_member_ids)

      new_namespace.update_metadata_summary_by_namespace_transfer(@group, old_namespace)

      true
    rescue Groups::TransferService::TransferError => e
      @group.errors.add(:new_namespace, e.message)
      false
    end

    private

    def validate(new_namespace)
      raise TransferError, I18n.t('services.groups.transfer.namespace_empty') if new_namespace.blank?

      return unless new_namespace.id == @group.id

      raise TransferError,
            I18n.t('services.groups.transfer.same_group_and_namespace')
    end

    def create_activities(old_namespace, new_namespace) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      if old_namespace && new_namespace

        old_namespace.create_activity key: 'group.transfer_out',
                                      owner: current_user,
                                      parameters:
                                      {
                                        transferred_group_id: @group.id,
                                        old_namespace: old_namespace.puid,
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        @group.create_activity key: 'group.transfer_out',
                               owner: current_user,
                               parameters:
                               {
                                 transferred_group_id: @group.id,
                                 old_namespace: old_namespace.puid,
                                 new_namespace: new_namespace.puid,
                                 action: 'group_namespace_transfer'
                               }

        new_namespace.create_activity key: 'group.transfer_in',
                                      owner: current_user,
                                      parameters:
                                      {
                                        transferred_group_id: @group.id,
                                        old_namespace: old_namespace.puid,
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        @group.create_activity key: 'group.transfer_in',
                               owner: current_user,
                               parameters:
                               {
                                 transferred_group_id: @group.id,
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
                                        new_namespace: new_namespace.puid,
                                        action: 'group_namespace_transfer'
                                      }

        @group.create_activity key: 'group.transfer_in_no_exisiting_namespace',
                               owner: current_user,
                               parameters:
                               {
                                 transferred_group_id: @group.id,
                                 new_namespace: new_namespace.puid,
                                 action: 'group_namespace_transfer'
                               }
      end
    end
  end
end
