# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      def edit
        authorize! @project, to: :update_sample?
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'edit_metadata_modal',
                                                 locals: {
                                                   open: true,
                                                   key: params[:key],
                                                   value: params[:value]
                                                 }), status: :ok
      end

      # Receives the already validated metadata_param from metadata/fields_controller#update
      def update
        authorize! @project, to: :update_sample?
        metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                 metadata_params).execute
        render_params = get_render_status_and_message(metadata_fields)
        respond_to do |format|
          format.turbo_stream do
            render status: render_params[:status],
                   locals: { type: render_params[:message][:type],
                             message: render_params[:message][:message],
                             table_listing: @sample.metadata_with_provenance }
          end
        end
      end

      private

      def metadata_params
        params.require(:sample).permit(:analysis_id, metadata: {})
      end

      def get_render_status_and_message(metadata_fields)
        render_params = {}
        modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
        if modified_metadata.count.positive?
          render_params[:status] = :ok
          render_params[:message] = { type: 'success', message: t('.success') }
        else
          render_params[:status] = :unprocessable_entity
          render_params[:message] = { type: 'error', message: @sample.errors.full_messages.first }
        end
        render_params
      end
    end
  end
end
