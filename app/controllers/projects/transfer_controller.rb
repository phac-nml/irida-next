# frozen_string_literal: true

module Projects
  class TransferController < Projects::ApplicationController
    before_action :project, only: %i[create]
    before_action :authorized_namespaces, only: %i[create]

    def create
      id = params.require(:new_namespace_id)
      new_namespace ||= Namespace.find_by(id:)
      if Projects::TransferService.new(@project, current_user).execute(new_namespace)
        flash[:success] = t('.success', project_name: @project.name)
        respond_to do |format|
          format.turbo_stream { redirect_to project_path(@project) }
        end
      else
        @error = @project.errors.messages.values.flatten.first
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def project_params
      params.require(:project)
            .permit(project_params_attributes)
    end

    def namespace_attributes
      %i[
        name
        path
        description
        parent_id
      ]
    end

    def project_params_attributes
      [
        namespace_attributes:
      ]
    end

    def project
      return unless params[:project_id]

      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_namespaces
      @authorized_namespaces = case action_name
                               when 'create'
                                 authorized_scope(Namespace, type: :relation, as: :transferable,
                                                             scope_options: { namespace: @project.namespace.parent })
                               end
    end
  end
end
