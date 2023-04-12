# frozen_string_literal: true

module Projects
  # Controller actions for Members
  class MembersController < ApplicationController
    include MembershipActions
    verify_authorized
    layout 'projects'

    def member_params
      params.require(:member).permit(:user_id, :access_level, :type, :namespace_id, :created_by_id)
    end

    private

    def member
      @member = Member.find_by(id: request.params[:id], namespace_id: member_namespace.id)
    end

    def namespace
      @namespace = member_namespace
      @member_type = 'ProjectMember'
    end

    protected

    def members_path
      namespace_project_members_path
    end

    def context_crumbs
      case action_name
      when 'index'
        @context_crumbs = [{
          name: I18n.t('projects.members.index.title'),
          path: namespace_project_members_path
        }]
      end
    end

    def member_namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @project.namespace
    end
  end
end
