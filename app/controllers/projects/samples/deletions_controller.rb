# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::ApplicationController
      before_action :sample, only: %i[new destroy]
      before_action :set_new_dialog_params, only: :new

      def new
        authorize! @project, to: :destroy_sample?
        render turbo_stream: turbo_stream.update('samples_dialog',
                                                 partial: @partial,
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def destroy
        ::Samples::DestroyService.new(@project.namespace, current_user, { sample: @sample }).execute

        respond_to do |format|
          if @sample.deleted?
            format.any(:html, :turbo_stream) do
              flash[:success] = t('.success', sample_name: @sample.name, project_name: @project.namespace.human_name)
              redirect_to namespace_project_samples_path
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { type: 'alert', message: error_message(@sample) }
            end
          end
        end
      end

      def destroy_multiple # rubocop:disable Metrics/AbcSize
        samples_to_delete_count = destroy_multiple_params['sample_ids'].count

        deleted_samples_count = ::Samples::DestroyService.new(@project.namespace, current_user,
                                                              destroy_multiple_params).execute

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

        redirect_to namespace_project_samples_path, status: :see_other
      end

      private

      def sample
        # Necessary return for new when deletion_type = 'multiple', as has no params[:sample_id] defined
        return if params[:deletion_type] == 'multiple'

        @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
      end

      def set_new_dialog_params
        if params['deletion_type'] == 'single'
          @partial = 'new_deletion_dialog'
        else
          @partial = 'shared/samples/destroy_multiple_confirmation_dialog'
          @list_path = list_namespace_project_samples_path(list_class: 'sample')
          @destroy_path = destroy_multiple_namespace_project_samples_deletion_path
        end
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
