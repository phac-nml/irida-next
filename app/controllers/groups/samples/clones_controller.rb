# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples Clone Controller
    class ClonesController < Groups::SamplesController
      respond_to :turbo_stream
      before_action :projects, :ensure_enabled

      def new
        authorize! @group, to: :clone_sample?
        @broadcast_target = "samples_clone_#{SecureRandom.uuid}"
      end

      def create
        @broadcast_target = params[:broadcast_target]
        new_project_id = clone_params[:new_project_id]
        sample_ids = clone_params[:sample_ids]
        Groups::Samples::CloneJob.set(wait_until: 1.second.from_now).perform_later(@group, current_user,
                                                                                   new_project_id,
                                                                                   sample_ids, @broadcast_target)

        render status: :ok
      end

      private

      def clone_params
        params.expect(clone: [:new_project_id, { sample_ids: [] }])
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :manageable)
      end

      def ensure_enabled
        not_found unless Flipper.enabled?(:group_samples_clone)
      end
    end
  end
end
