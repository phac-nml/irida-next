# frozen_string_literal: true

module Groups
  # Controller actions for Members
  class MembersController < Groups::ApplicationController
    include MembershipActions
    layout 'groups'

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member = Member.find_by(id: request.params[:id], namespace_id: member_namespace.id) || not_found
    end

    def namespace
      @namespace = member_namespace
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

    def authorize_view_members
      authorize_view_group!
    end

    def authorize_modify_members
      authorize_modify_group!
    end
  end
end
