# frozen_string_literal: true

module Projects
  # Controller actions for Members
  class MembersController < ApplicationController
    include MembershipActions

    before_action :member, only: %i[destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :namespace, only: %i[index new create destroy] # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :access_levels, only: %i[new create] # rubocop:disable Rails/LexicallyScopedActionFilter

    layout 'projects'

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member = Member.find_by(id: request.params[:id])
    end

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
      @member_type = 'ProjectMember'
    end

    protected

    def members_path
      namespace_project_members_path
    end
  end
end
