# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class MetadataController < Projects::Samples::ApplicationController
      def update # rubocop:disable Metrics
        authorize! @project, to: :update_sample?

        metadata_change = find_changed_metadata(form_metadata_params['metadata'])
        validate_new_key(metadata_change[:new_key]) if metadata_change[:field_to_change] == 'key'

        metadata_params = build_metadata_for_update(metadata_change)
        respond_to do |format|
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if modified_metadata.count.positive?
            flash[:success] =
              t('.success', metadata_fields: metadata_fields[:updated].join(', '), sample_name: @sample.name)
          end
          flash[:error] = @sample.errors.full_messages.first if @sample.errors.any?
          format.turbo_stream { redirect_to(namespace_project_sample_path(id: @sample.id, tab: 'metadata')) }
        end
      end

      private

      def form_metadata_params
        params.require(:sample).permit(:analysis_id, metadata: {})
      end

      def find_changed_metadata(metadata)
        metadata_to_update = { field_to_change: '', original_value: '', new_value: '' }
        metadata.each do |k, v|
          key = k.split('_')[0]
          type = k.split('_')[1]
          if type == 'key'
            metadata_to_update = { field_to_change: 'key', original_key: key, new_key: v } if key != v
          elsif @sample.metadata[key] != v
            metadata_to_update = { field_to_change: 'value', original_key: key, new_value: v }
          end
        end
        metadata_to_update
      end

      def validate_new_key(key); end

      def build_metadata_for_update(metadata)
        if metadata[:field_to_change] == 'key'
          { 'metadata' => { metadata[:original_key] => '',
                            metadata[:new_key] => @sample.metadata[metadata[:original_key]] } }
        else
          { 'metadata' => { metadata[:original_key] => metadata[:new_value] } }
        end
      end
    end
  end
end
