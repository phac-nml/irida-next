# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      def edit
        authorize! @project, to: :update_sample?
        render turbo_stream: turbo_stream.update('sample_files_modal',
                                                 partial: 'edit_metadata_modal',
                                                 locals: {
                                                   open: true,
                                                   key: params[:key],
                                                   value: params[:value]
                                                 }), status: :ok
      end

      def update
        authorize! @project, to: :update_sample?
        respond_to do |format|
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if modified_metadata.count.positive?
            format.turbo_stream do
              render status: :ok, locals: { type: 'success',
                                            message: t('.success'),
                                            table_listing: @sample.metadata_with_provenance }
            end
          end
        end
      end

      private

      # new service field-update-service
      # new controller
      #   samples-metadata-field-update-controller
      #   - initially receives payload
      #   - check key_exists
      #   - create payload for updateservice
      def metadata_params
        params.require(:sample).permit(:analysis_id, metadata: {})
      end

      # When editing a param, we receive a single param that will have a key containing what field will be edited and
      # the metadata key, and a value that will either be the new metadata key or value
      # Example:
      # For a key update, we will receive:
      # param = {key_metadatakey1: metadatakey2} where the old key metadatakey1 will be updated to metadatakey2
      #
      # For a value update, we will receive:
      # param = {value_metadatakey1: newvalue1} where we will update metadatakey1 to value newvalue1
      def parse_metadata_input(param)
        split_metadata_hash = param.keys[0].split('_')
        field_to_edit = split_metadata_hash[0]
        if field_to_edit == 'key'
          { field_to_edit:, old_key: split_metadata_hash[1],
            new_key: metadata_params['metadata'].values[0] }
        else
          { field_to_edit:, key: split_metadata_hash[1],
            new_value: metadata_params['metadata'].values[0] }
        end
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
        if metadata[:field_to_edit] == 'key'
          { 'metadata' => { metadata[:new_key] => @sample.metadata[metadata[:old_key]],
                            metadata[:old_key] => '' } }
        else
          { 'metadata' => { metadata[:key] => metadata[:new_value] } }
        end
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
