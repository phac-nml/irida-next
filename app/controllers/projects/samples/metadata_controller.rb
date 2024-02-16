# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      def new
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'new_metadata_modal',
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def edit
        authorize! @project, to: :update_sample?
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'update_metadata_modal',
                                                 locals: {
                                                   open: true,
                                                   key: params[:key],
                                                   value: params[:value]
                                                 }), status: :ok
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

      private

      def deletion_params
        params.require(:sample).permit(metadata: {})
      end
    end
  end
end
