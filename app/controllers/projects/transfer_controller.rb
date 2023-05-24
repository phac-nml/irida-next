# frozen_string_literal: true

module Projects
  class TransferController < Projects::ApplicationController
    before_action :project, only: %i[create]

    def create
      id = params.require(:new_namespace_id)
      new_namespace ||= Namespace.find_by(id:)
      if Projects::TransferService.new(@project, current_user).execute(new_namespace)
        redirect_to(
          project_path(@project),
          notice: t('.success', project_name: @project.name)
        )
      else
        @value = id
        render :edit_transfer, status: :unprocessable_entity,
                               locals: { type: 'alert', message: @project.errors.messages.values.flatten.first }
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
                               when 'edit', 'transfer'
                                 authorized_scope(Namespace, type: :relation, as: :transferable,
                                                             scope_options: { namespace: @project.namespace.parent })
                               end
    end
  end
end
