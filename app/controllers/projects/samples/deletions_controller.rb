# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::ApplicationController
      before_action :sample, only: %i[new destroy]
      before_action :new_dialog_partial, only: :new

      def new
        authorize! @project, to: :destroy_sample?
        render turbo_stream: turbo_stream.update('samples_dialog',
                                                 partial: @partial,
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ::Samples::DestroyService.new(@project, current_user, { sample: @sample }).execute

        respond_to do |format|
          if @sample.deleted?
            flash[:success] = t('.success', sample_name: @sample.name, project_name: @project.namespace.human_name)
            format.html do
              redirect_to namespace_project_samples_path(format: :html)
            end
            format.turbo_stream do
              redirect_to namespace_project_samples_path
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { type: 'alert', message: @sample.errors.full_messages.first }
            end
          end
        end
      end

      def destroy_multiple
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

      def sample
        # Necessary return for new when deletion_type = 'multiple', as has no params[:sample_id] defined
        return if params[:deletion_type] == 'multiple'

        @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
      end

      def new_dialog_partial
        @partial = params['deletion_type'] == 'single' ? 'new_deletion_dialog' : 'new_multiple_deletions_dialog'
      end

      def destroy_multiple_params
        params.require(:multiple_deletion).permit(sample_ids: [])
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
