# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples Transfer
    class TransfersController < Groups::SamplesController
      respond_to :turbo_stream
      before_action :projects
      before_action :ensure_enabled

      def new
        authorize! @group, to: :transfer_sample?

        @broadcast_target = "samples_transfer_#{SecureRandom.uuid}"
      end

      def create
        @broadcast_target = params[:broadcast_target]
        new_project_id = transfer_params[:new_project_id]
        sample_ids = transfer_params[:sample_ids]
        Groups::Samples::TransferJob.set(wait_until: 1.second.from_now).perform_later(@group, current_user,
                                                                                      new_project_id,
                                                                                      sample_ids, @broadcast_target)

        render status: :ok
      end

      private

      def transfer_params
        params.expect(transfer: [:new_project_id, { sample_ids: [] }])
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :project_samples_transferable,
                                              scope_options: { group: @group })
      end

      def ensure_enabled
        not_found unless Flipper.enabled?(:group_samples_transfer)
      end
    end
  end
end
