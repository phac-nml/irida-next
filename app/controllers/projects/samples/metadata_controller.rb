# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      def new
        render turbo_stream: turbo_stream.update('sample_files_modal',
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

      def create # rubocop:disable Metrics
        metadata_to_add = add_metadata_params['metadata'].split('{')[1].split('}')[0].split(',')
        metadata_params_for_update = { 'metadata' => {} }
        metadata_to_add.each do |metadata|
          key = metadata.split(':')[0].split('"')[1]
          value = metadata.split(':')[1].split('"')[1]
          metadata_params_for_update['metadata'][key] = value
        end
        metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                 metadata_params_for_update).execute
        respond_to do |format|
          if metadata_fields[:added].count.positive?
            format.turbo_stream do
              render status: :ok, locals: { type: 'success',
                                            message: t('.success', keys: metadata_fields[:added].join(', '),
                                                                   sample_name: @sample.name),
                                            table_listing: @sample.metadata_with_provenance }
            end
          end
        end
      end

      def update # rubocop:disable Metrics/AbcSize
        authorize! @project, to: :update_sample?
        respond_to do |format|
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if modified_metadata.count.positive?
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

      def add_metadata_params
        params.require(:sample).permit(:metadata)
      end
    end
  end
end
