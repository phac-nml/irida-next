# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Groups::ApplicationController
      before_action :group
      before_action :sample, only: %i[new destroy]
      before_action :new_dialog_partial, only: :new

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

        deleted_samples_count = ::Samples::DestroyService.new(@project, current_user, destroy_multiple_params).execute

        # No selected samples deleted
        if deleted_samples_count.zero?
          flash[:error] = t('.no_deleted_samples')
        # Partial sample deletion
        elsif deleted_samples_count.positive? && deleted_samples_count != samples_to_delete_count
          set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
        # All samples deleted successfully
        else
          flash[:success] = t('.success')
        end

        redirect_to namespace_project_samples_path
      end

      private

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end

      def sample
        # Necessary return for new when deletion_type = 'multiple', as has no params[:sample_id] defined
        return if params[:deletion_type] == 'multiple'

        @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
      end

      def new_dialog_partial
        @partial = params['deletion_type'] == 'single' ? 'new_deletion_dialog' : 'new_multiple_deletions_dialog'
      end

      def destroy_multiple_params
        params.expect(multiple_deletion: [sample_ids: []])
      end

      def set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
        flash[:success] = t('projects.samples.deletions.destroy_multiple.partial_success',
                            deleted: "#{deleted_samples_count}/#{samples_to_delete_count}")
        flash[:error] = t('projects.samples.deletions.destroy_multiple.partial_error',
                          not_deleted: "#{samples_to_delete_count - deleted_samples_count}/#{samples_to_delete_count}")
      end
    end
  end
end
