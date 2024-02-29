# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Transfer
    class TransfersController < Projects::ApplicationController
      respond_to :turbo_stream
      before_action :projects

      def new
        authorize! @project, to: :transfer_sample?

        @q = load_samples.ransack(params[:q])
        respond_to do |format|
          format.turbo_stream do
            render status: :ok
          end
        end
      end

      def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        new_project_id = transfer_params[:new_project_id]
        sample_ids = transfer_params[:sample_ids]
        transferred_samples_ids = ::Samples::TransferService.new(@project, current_user).execute(new_project_id,
                                                                                                 sample_ids)
        @q = load_samples.ransack(params[:q])
        @pagy, @samples = pagy(@q.result)

        if transferred_samples_ids.length == sample_ids.length
          render status: :ok, locals: { type: :success, message: t('.success') }
        elsif @project.errors.include?(:samples)
          errors = @project.errors.messages_for(:samples)
          render status: :partial_content,
                 locals: { type: :alert, message: t('.error'), errors: }
        else
          errors = @project.errors.full_messages_for(:base)
          render status: :unprocessable_entity,
                 locals: { type: :alert, message: t('.no_samples_transferred_error'), errors: }
        end
      end

      private

      def transfer_params
        params.require(:transfer).permit(:new_project_id, sample_ids: [])
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :project_samples_transferable,
                                              scope_options: { project: })
                    .where.not(namespace_id: project.namespace_id)
      end
    end
  end
end
