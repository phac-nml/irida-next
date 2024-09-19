# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    attr_accessor :group

    def initialize(user = nil, params = {})
      super
      @group = Group.new(params.merge(owner: current_user))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      authorize! group.parent, to: :create_subgroup? if params[:parent_id]

      group.save

      if group.persisted?
        @group.create_activity key: 'group.create',
                               owner: current_user
        if group.parent.nil?
          Members::CreateService.new(current_user, group, {
                                       user: current_user,
                                       access_level: Member::AccessLevel::OWNER
                                     }).execute

        else
          @group.parent.create_activity key: 'group.subgroups.create',
                                        owner: current_user,
                                        parameters: {
                                          created_group_id: @group.id,
                                          action: 'group_subgroup_create'
                                        }
        end

      end

      group
    end
  end
end
