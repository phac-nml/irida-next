# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Transfer
    class TransfersController < Projects::ApplicationController
      respond_to :turbo_stream
      before_action :projects

      def new
        authorize! @project, to: :transfer_sample?

        respond_to do |format|
          format.turbo_stream do
            render status: :ok
          end
        end
      end

      def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        new_project_id = transfer_params[:new_project_id]
        sample_ids = transfer_params[:sample_ids]
        @transferred_samples_ids = ::Samples::TransferService.new(@project, current_user).execute(new_project_id,
                                                                                                  sample_ids)

        @project.namespace.create_activity key: 'namespaces_project_namespace.samples.transfer', owner: current_user,
                                           parameters:
                                         {
                                           project_name: @project.name,
                                           new_project_name: Project.find(new_project_id).namespace.name,
                                           transferred_samples_ids: @transferred_samples_ids.join
                                         }

        if @project.errors.empty?
          render status: :ok, locals: { type: :success, message: t('.success') }
        elsif @project.errors.include?(:samples)
          render_sample_errors
        else
          errors = @project.errors.full_messages_for(:base)
          render status: :unprocessable_entity,
                 locals: { type: :alert, message: t('.no_samples_transferred_error'),
                           errors: }
        end
      end

      private

      def transfer_params
        params.require(:transfer).permit(:new_project_id, sample_ids: [])
      end

      def render_sample_errors
        errors = @project.errors.messages_for(:samples)
        if @transferred_samples_ids.count.positive?
          render status: :partial_content,
                 locals: { type: :alert, message: t('projects.samples.transfers.create.error'),
                           errors: }
        else
          render status: :unprocessable_entity,
                 locals: { type: :alert, message: t('projects.samples.transfers.create.error'),
                           errors: }
        end
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :project_samples_transferable,
                                              scope_options: { project: })
                    .where.not(namespace_id: project.namespace_id)
      end
    end
  end
end
