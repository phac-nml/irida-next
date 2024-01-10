# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class MetadataController < Projects::Samples::ApplicationController
      def update # rubocop:disable Metrics/AbcSize
        authorize! @project, to: :update_sample?
        respond_to do |format|
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          changed_metadata_fields = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if changed_metadata_fields.count.positive?
            flash[:success] =
              t('.success', metadata_fields: metadata_fields[:updated].join(', '), sample_name: @sample.name)
          end
          flash[:error] = @sample.errors.full_messages.first if @sample.errors.any?
          format.turbo_stream { redirect_to(project_path(@project)) }
        end
      end

      private

      def metadata_params
        params.require(:metadata).permit(:analysis_id, metadata: {})
      end
    end
  end
end
