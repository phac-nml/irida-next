# frozen_string_literal: true

module Groups
  # Controller actions for Members
  class MembersController < ApplicationController
    include MembershipActions

    before_action :member, only: %i[destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :namespace, only: %i[index new create] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :access_levels, only: %i[new create] # rubocop:disable Rails/LexicallyScopedActionFilter

    layout :resolve_layout

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member ||= Member.find_by(id: request.params[:member_id])
    end

    def namespace
      @namespace ||= Namespace.find_by(path: group_path ||
                      request.params[:namespace_id])
      @member_type = 'GroupMember'
      @group = @namespace
    end

    def access_levels
      @access_levels = Member::AccessLevel.access_level_options
    end

    def group_path
      # gets group/subgroup path
      request.params[:id].rpartition('/').last
    end

    def resolve_layout
      case action_name
      when 'new', 'create', 'index'
        if @namespace && @namespace.type == 'Group'
          'groups'
        else
          'application'
        end
      else
        'application'
      end
    end
  end
end
