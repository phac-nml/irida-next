# frozen_string_literal: true

module Groups
  # Controller actions for Members
  class MembersController < ApplicationController
    include MembershipActions

    layout 'groups'

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member = Member.find_by(id: request.params[:id], namespace_id: member_namespace.id)
    end

    def namespace
      @namespace = member_namespace
      @member_type = 'GroupMember'
    end

    protected

    def members_path
      group_members_path
    end

    def context_crumbs
      case action_name
      when 'index', 'new'
        @context_crumbs = [{
          name: I18n.t('groups.members.index.title'),
          path: group_members_path
        }]
      end
    end

    def member_namespace
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @group
    end
  end
end
