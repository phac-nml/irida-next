# frozen_string_literal: true

module Projects
  # Controller actions for Projects::ShareController
  class ShareController < Projects::ApplicationController
    before_action :project_namespace

    def create # rubocop:disable Metrics/AbcSize
      namespace_group_link = Groups::ShareService.new(current_user, params[:shared_group_id], @project_namespace,
                                                      params[:group_access_level]).execute
      if namespace_group_link
        if namespace_group_link.errors.full_messages.count.positive?
          flash[:error] = namespace_group_link.errors.full_messages.first
          render :edit, status: :conflict
        else
          flash[:success] = 'Successfully shared project with group'
          # redirect_to group_path(@group)
          redirect_to namespace_project_path(@project_namespace.parent, @project_namespace.project)
        end
      else
        flash[:error] = 'There was an error sharing project with group'
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def project_namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @project_namespace = @project.namespace
      @project_namespace
    end

    def share_params
      params.permit(:shared_group_id)
    end
  end
end
