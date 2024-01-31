# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to validate the edit_fields param and construct the metadata update param to be passed
      # to metadata_controller#update and Samples::Metadata::UpdateService
      class AddService < BaseService
        SampleMetadataFieldsAddError = Class.new(StandardError)
        attr_accessor :project, :sample, :add_fields, :metadata_update_params

        def initialize(project, sample, user = nil, add_fields = {})
          super(user, params)
          @project = project
          @sample = sample
          @add_fields = add_fields
          @metadata_update_params = { 'metadata' => {}, 'existing_keys' => [] }
        end

        def execute
          authorize! @project, to: :update_sample?

          validate_sample_in_project

          construct_metadata_update_params

          validate_new_added_keys

          updated_metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                           @metadata_update_params).execute

          { added_keys: updated_metadata_fields[:added],
            existing_keys: @metadata_update_params['existing_keys'] }
        rescue Samples::Metadata::Fields::AddService::SampleMetadataFieldsAddError => e
          @sample.errors.add(:base, e.message)
          @metadata_update_params
        end

        private

        def validate_sample_in_project
          return unless @project.id != @sample.project.id

          raise SampleMetadataFieldsAddError,
                I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project',
                       sample_name: @sample.name, project_name: @project.name)
        end

        # Constructs the expected param for metadata update_service
        def construct_metadata_update_params
          @add_fields.each do |k, v|
            if validate_key(k)
              @metadata_update_params['existing_keys'] << k
            else
              @metadata_update_params['metadata'][k] = v
            end
          end
        end

        # Checks if the new key already exists within the @sample.metadata
        def validate_key(key)
          key_exists = false
          @sample.metadata.each do |k, _v|
            if k.downcase == key.downcase
              key_exists = true
              break
            end
          end
          key_exists
        end

        # Checks if all new keys already exist
        def validate_new_added_keys
          return unless @metadata_update_params['metadata'].empty?

          raise SampleMetadataFieldsAddError,
                I18n.t('services.samples.metadata.fields.all_keys_exist',
                       keys: @metadata_update_params['existing_keys'].join(', '))
        end
      end
    end
  end
end
