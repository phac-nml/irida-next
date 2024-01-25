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

      def get_flash_message(metadata_fields, metadata_to_update)
        if metadata_fields[:added].count.positive? && metadata_fields[:deleted].count.positive?
          t('.key_change_success', old_key: metadata_fields[:deleted][0], new_key: metadata_fields[:added][0])
        else
          t('.value_change_success', key: metadata_fields[:updated][0], value: metadata_to_update[:new_value])
        end
      end
    end
  end
end
