# frozen_string_literal: true

module Projects
  # Controller actions for Project Group Links
  class GroupLinksController < Projects::ApplicationController
    include ShareActions

    def group_link_params
      params.require(:namespace_group_link).permit(:id, :group_id, :namespace_id, :group_access_level, :expires_at)
    end

    private

    def namespace_group_link
      @namespace_group_link ||= @project.namespace.shared_with_group_links
                                        .find_by(id: params[:id])
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
          name: I18n.t('projects.members.index.title'),
          path: group_links_path
        }]
      end
    end

    def group_link_namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @project.namespace
    end
  end
end
