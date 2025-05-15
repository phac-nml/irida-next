# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Groups::ApplicationController
      before_action :group
      before_action :new_dialog_partial, :new_dialog_paths, only: :new

      def new
        authorize! @group, to: :destroy_sample?
        render turbo_stream: turbo_stream.update('samples_dialog',
                                                 partial: 'shared/samples/destroy_multiple_confirmation_dialog',
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def destroy
        samples_to_delete_count = destroy_multiple_params['sample_ids'].count

        deleted_samples_count = ::Samples::DestroyService.new(@group, current_user, destroy_multiple_params).execute

        # No selected samples deleted
        if deleted_samples_count.zero?
          flash[:error] = t('shared.samples.destroy_multiple.no_deleted_samples')
        # Partial sample deletion
        elsif deleted_samples_count.positive? && deleted_samples_count != samples_to_delete_count
          set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
        # All samples deleted successfully
        else
          flash[:success] = t('shared.samples.destroy_multiple.success')
        end

        redirect_to group_samples_path
      end

      private

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end

      def new_dialog_partial
        @partial = params['deletion_type'] == 'single' ? 'new_deletion_dialog' : 'new_multiple_deletions_dialog'
      end

      def new_dialog_paths
        @list_path = list_group_samples_path(list_class: 'sample')
        @destroy_path = group_samples_deletion_path
      end

      def destroy_multiple_params
        params.expect(multiple_deletion: [sample_ids: []])
      end

      def set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
        flash[:success] = t('shared.samples.destroy_multiple.partial_success',
                            deleted: "#{deleted_samples_count}/#{samples_to_delete_count}")
        flash[:error] = t('shared.samples.destroy_multiple.partial_error',
                          not_deleted: "#{samples_to_delete_count - deleted_samples_count}/#{samples_to_delete_count}")
      end
    end
  end
end
