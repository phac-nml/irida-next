# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Clone Controller
    class ClonesController < Projects::ApplicationController
      respond_to :turbo_stream
      before_action :projects

      def new
        @broadcast_target = "samples_clone_#{SecureRandom.uuid}"
      end

      def create
        @broadcast_target = params[:broadcast_target]
        new_project_id = clone_params[:new_project_id]
        sample_ids = clone_params[:sample_ids]
        @samples_count = sample_ids.length

        ::Samples::CloneJob.set(wait_until: 1.second.from_now).perform_later(@project, current_user, new_project_id,
                                                                             sample_ids, @broadcast_target)

        render status: :ok
      end

      private

      def clone_params
        params.require(:clone).permit(:new_project_id, sample_ids: [])
      end

      def projects
        @projects = authorized_scope(Project, type: :relation,
                                              as: :manageable).where.not(namespace_id: @project.namespace_id)
      end
    end
  end
end
