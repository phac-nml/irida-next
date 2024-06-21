# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::ApplicationController
      include Metadata
      # before_action :sample, only: %i[new destroy]
      # before_action :current_page
      before_action :set_search_params, only: %i[destroy destroy_multiple]

      def new
        if params['deletion_type'] == 'single'
          @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
          render turbo_stream: turbo_stream.update('samples_dialog',
                                                   partial: 'new_deletion_dialog',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        else
          render turbo_stream: turbo_stream.update('samples_dialog',
                                                   partial: 'new_multiple_deletions_dialog',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end
      end

      def destroy # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
        ::Samples::DestroyService.new(@sample, current_user).execute
        @pagy, @samples = pagy(load_samples)
        @q = load_samples.ransack(params[:q])

        if @sample.deleted?
          respond_to do |format|
            format.html do
              flash[:success] = t('.success', sample_name: @sample.name, project_name: @project.namespace.human_name)
              redirect_to namespace_project_samples_path(format: :html)
            end
            format.turbo_stream do
              @fields = !(params[:q] && params[:q][:metadata].to_i == 1) || @project.namespace.nil? ? [] : @project.namespace.metadata_fields
              render status: :ok, locals: { type: 'success',
                                            message: t('.success', sample_name: @sample.name,
                                                                   project_name: @project.namespace.human_name) }
            end
          end
        else
          respond_to do |format|
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { type: 'alert', message: @sample.errors.full_messages.first }
            end
          end
        end
      end

      def destroy_multiple
        authorize! @project, to: :destroy_sample?

        samples_to_delete_count = destroy_multiple_params['sample_ids'].count

        deleted_samples_count = ::Samples::MultiDestroyService.new(@project, destroy_multiple_params['sample_ids'],
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
        @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
      end

      def set_search_params
        @search_params = params[:q].nil? ? {} : params[:q].to_unsafe_h
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
