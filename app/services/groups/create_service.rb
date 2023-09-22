# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    attr_accessor :group

    def initialize(user = nil, params = {})
      super(user, params)
      @group = Group.new(params.merge(owner: current_user))
    end

    def execute
      authorize! group.parent, to: :create_subgroup? if params[:parent_id]

      group.save

      if group.parent.nil? && group.persisted?
        Members::CreateService.new(current_user, group, {
                                     user: current_user,
                                     access_level: Member::AccessLevel::OWNER
                                   }).execute
      end

      group
    end
  end
end
