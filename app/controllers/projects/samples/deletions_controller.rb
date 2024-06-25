# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::ApplicationController
      before_action :new_dialog_partial, only: :new

      def new
        authorize! @project, to: :destroy_sample?

        if params[:deletion_type] == 'single'
          @sample = Sample.find_by(id: params[:sample_id], project_id: project.id) || not_found
        end

        render turbo_stream: turbo_stream.update('samples_dialog',
                                                 partial: @partial,
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def destroy # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @sample = ::Samples::DestroyService.new(@project, params[:sample_id], current_user).execute
        respond_to do |format|
          if @sample.deleted?
            format.html do
              flash[:success] = t('.success', sample_name: @sample.name, project_name: @project.namespace.human_name)
              redirect_to namespace_project_samples_path(format: :html)
            end
            format.turbo_stream do
              render status: :ok, locals: { type: 'success',
                                            message: t('.success', sample_name: @sample.name,
                                                                   project_name: @project.namespace.human_name) }
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

        deleted_samples_count = ::Samples::DestroyService.new(@project, destroy_multiple_params['sample_ids'],
                                                              current_user).execute

        # No selected samples deleted
        if deleted_samples_count.zero?
          render status: :unprocessable_entity, locals: { type: :error, message: t('.no_deleted_samples') }
        # Partial sample deletion
        elsif deleted_samples_count.positive? && deleted_samples_count != samples_to_delete_count
          render status: :multi_status,
                 locals: { messages: get_multi_status_destroy_multiple_message(deleted_samples_count,
                                                                               samples_to_delete_count) }
        # All samples deleted successfully
        else
          render status: :ok, locals: { type: :success, message: t('.success') }
        end
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

      def get_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
        [
          { type: :success,
            message: t('.partial_success',
                       deleted: "#{deleted_samples_count}/#{samples_to_delete_count}") },
          { type: :error,
            message: t('.partial_error',
                       not_deleted: "#{samples_to_delete_count - deleted_samples_count}/#{samples_to_delete_count}") }
        ]
      end
    end
  end
end
