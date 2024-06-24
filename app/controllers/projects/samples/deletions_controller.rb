# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Deletions
    class DeletionsController < Projects::Samples::ApplicationController
      before_action :sample, only: %i[destroy]
      # before_action :current_page
      before_action :set_search_params, only: %i[destroy destroy_multiple]

      def new
        puts params
        if params['deletion_type'] == 'single'
          render turbo_stream: turbo_stream.update('samples_dialog',
                                                   partial: 'new_deletions_modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        else
          render turbo_stream: turbo_stream.update('samples_dialog',
                                                   partial: 'new_multiple_deletions_modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end
      end

      def destroy
        metadata = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                          deletion_params).execute
        respond_to do |format|
          if metadata[:deleted].count.positive?
            format.turbo_stream do
              render status: :ok, locals: { type: 'success',
                                            message: t('.success', deleted_key: metadata[:deleted][0]) }
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity, locals: { type: 'error', message: t('.error') }
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
