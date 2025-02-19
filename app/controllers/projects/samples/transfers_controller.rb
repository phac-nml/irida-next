# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Transfer
    class TransfersController < Projects::ApplicationController
      respond_to :turbo_stream
      before_action :projects

      def new
        authorize! @project, to: :transfer_sample?

        @broadcast_target = "samples_transfer_#{SecureRandom.uuid}"
      end

      def create
        @broadcast_target = params[:broadcast_target]
        new_project_id = transfer_params[:new_project_id]
        sample_ids = transfer_params[:sample_ids]
        @samples_count = sample_ids.count
        ::Samples::TransferJob.set(wait_until: 1.second.from_now)
                              .perform_later(@project, current_user, new_project_id, sample_ids, @broadcast_target)

        render status: :ok
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
