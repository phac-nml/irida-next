# frozen_string_literal: true

module Groups
  # Service used to share a group with another group
  class ShareService < BaseService
    GroupShareError = Class.new(StandardError)
    attr_accessor :group, :share_with_group_id, :max_group_access_role

    def initialize(user, group, share_with_group_id, max_group_access_role)
      super(user, group)
      @group = group
      @share_with_group_id = share_with_group_id
      @max_group_access_role = max_group_access_role
    end

    def execute
      authorize! group, to: :share_group_with_other_groups?

      group_to_share_with = Group.find_by(id: share_with_group_id)

      if group_to_share_with.nil?
        raise GroupShareError, I18n.t('services.groups.share.group_not_found',
                                      group_id: share_with_group_id,
                                      group: group.name)
      end

      group_group_link = GroupGroupLink.new(shared_group: group, shared_with_group: group_to_share_with,
                                            group_access_level: max_group_access_role)

      group_group_link.save

      group_group_link
    rescue Groups::ShareService::GroupShareError => e
      @group.errors.add(:base, e.message)
      false
    end
  end
end
