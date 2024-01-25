# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class MetadataController < Projects::Samples::ApplicationController
      def update # rubocop:disable Metrics
        authorize! @project, to: :update_sample?

        metadata_to_update = find_metadata_update(form_metadata_params['metadata'])
        status = ''
        render_locals = ''
        if metadata_to_update[:field_to_change] == 'key' && validate_new_key(metadata_to_update[:new_key])
          status = :unprocessable_entity
          render_locals = { type: 'error',
                            message: t('.key_exists', key: metadata_to_update[:new_key]),
                            table_listing: @sample.metadata_with_provenance }
        else
          metadata_params = build_metadata_for_update(metadata_to_update)

          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if modified_metadata.count.positive?
            status = :ok
            render_locals = { type: 'success',
                              message: t('.success', metadata_fields: metadata_fields[:updated].join(', '),
                                                     sample_name: @sample.name),
                              table_listing: @sample.metadata_with_provenance }

          end

          # flash[:error] = @sample.errors.full_messages.first if @sample.errors.any?
        end
        respond_to do |format|
          format.turbo_stream do
            render status:, locals: render_locals
          end
        end
      end

      private

      def form_metadata_params
        params.require(:sample).permit(:analysis_id, metadata: {})
      end

      # find_metadata_update will receive all of a sample's metadata in the following format:
      # if sample.metadata = {metadatafield1: value1, metadatafield2: value2},
      # The metadata argument below will be:
      # {metadatafield1_key: metadatafield1,
      #   metadatafield1_value: value1,
      #   metadatafield2_key: metadatafield2,
      #   metadatafield2_value: value2}
      # We will loop through the hash, split off key or value and assign that to type so we know what we're comparing
      # to, find what has been changed and return metadata_to_update containing the field that changed (key or value),
      # its original and its changed value.
      def find_metadata_update(metadata)
        metadata_to_update = {}
        metadata.each do |metadata_key, key_or_value_to_check|
          key = metadata_key.split('_')[0]
          type = metadata_key.split('_')[1]
          if type == 'key' && key != key_or_value_to_check
            metadata_to_update = { field_to_change: 'key', original_key: key, new_key: key_or_value_to_check }
            break
          elsif @sample.metadata[key] != key_or_value_to_check
            metadata_to_update = { field_to_change: 'value', original_key: key, new_value: key_or_value_to_check }
            break
          end
        end
        metadata_to_update
      end

      # Checks to ensure the user has not changed a metadata key to one that already exists
      def validate_new_key(key)
        key_exists = false
        @sample.metadata.each do |k, _v|
          if k.downcase == key.downcase
            key_exists = true
            break
          end
        end
        key_exists
      end

      # Takes the hash containing the metadata change from find_metadata_update and puts the metadata to update into
      # the expected update_service format. If the key is being changed, we delete the old key and create a new key
      # with the old value. If the value is changed, we simply overwrite the old value.
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
