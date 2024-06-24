# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::Samples::ApplicationController
      # before_action :sample, only: %i[destroy]
      # before_action :current_page
      # before_action :set_search_params, only: %i[destroy destroy_multiple]

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
        puts params
        puts hi
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
              fields_for_namespace(
                namespace: @project.namespace,
                show_fields: params[:q] && params[:q][:metadata].to_i == 1
              )
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
        'test'
      end

      private

      def deletion_params
        params.require(:sample).permit(metadata: {})
      end
    end
  end
end
