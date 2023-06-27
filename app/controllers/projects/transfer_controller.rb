# frozen_string_literal: true

module Projects
  # Controller for transferring projects to another namespace
  class TransferController < Projects::ApplicationController
    before_action :project, only: %i[create]
    before_action :authorized_namespaces, only: %i[create]

    def create
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

    def new_namespace
      id = params.require(:new_namespace_id)
      Namespace.find_by(id:)
    end

    def project
      return unless params[:project_id]

      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_namespaces
      @authorized_namespaces = authorized_scope(Namespace, type: :relation,
                                                           as: :manageable).where.not(id: @project.namespace.parent.id)
    end
  end
end
