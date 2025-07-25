# frozen_string_literal: true

module Projects
  # Controller actions for Members
  class MembersController < Projects::ApplicationController
    include MembershipActions

    before_action :current_page
    before_action :page_title

    def member_params
      params.expect(member: %i[user_id access_level type namespace_id created_by_id expires_at])
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
      namespace_project_members_path
    end

    def context_crumbs
      super
      case action_name
      when 'index', 'new'
        @context_crumbs += [{
          name: I18n.t('projects.members.index.title'),
          path: namespace_project_members_path
        }]
      end
    end

    def member_namespace
      @project.namespace
    end

    def current_page
      @current_page = t(:'projects.sidebar.members')
    end

    def page_title
      @title = if @tab == 'invited_groups'
                 [t(:'projects.members.index.invited_groups'), @project.full_name].join(' · ')
               else
                 [t(:'projects.sidebar.members'), @project.full_name].join(' · ')
               end
    end
  end
end
