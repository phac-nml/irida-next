# frozen_string_literal: true

module Groups
  # Controller actions for Members
  class MembersController < ApplicationController
    include MembershipActions

    before_action :member, only: %i[destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :namespace, only: %i[index new create destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :access_levels, only: %i[new create] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :context_crumbs, only: %i[index] # rubocop:disable Rails/LexicallyScopedActionFilter

    layout 'groups'

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member = Member.find_by(id: request.params[:id])
    end

    def namespace
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @namespace = @group
      @member_type = 'GroupMember'
    end

    def access_levels
      @access_levels = Member::AccessLevel.access_level_options
    end

    protected

    def members_path
      group_members_path
    end

    def context_crumbs
      case action_name
      when 'index'
        @context_crumbs = [{
          name: I18n.t('groups.members.index.title'),
          path: group_members_path
        }]
      end
    end
  end
end
