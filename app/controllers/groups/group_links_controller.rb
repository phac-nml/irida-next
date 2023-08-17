# frozen_string_literal: true

module Groups
  # Controller actions for Group Group Links
  class GroupLinksController < Groups::ApplicationController
    include ShareActions

    def group_link_params
      params.require(:namespace_group_link).permit(:group_id, :group_access_level, :expires_at)
    end

    private

    def namespace_group_link
      @namespace_group_link ||= NamespaceGroupLink.find_by(id: params[:id])
    end

    def namespace
      @namespace = group_link_namespace
    end

    protected

    def group_links_path
      group_group_links_path
    end

    def context_crumbs
      case action_name
      when 'index'
        @context_crumbs = [{
          name: I18n.t('groups.members.index.title'),
          path: group_links_path
        }]
      end
    end

    def group_link_namespace
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @group
    end
  end
end
