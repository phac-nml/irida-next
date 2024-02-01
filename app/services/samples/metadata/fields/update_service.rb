# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to validate the update_fields param and construct the metadata update param to be passed
      # to metadata_controller#update and Samples::Metadata::UpdateService
      class UpdateService < BaseService
        SampleMetadataFieldsUpdateError = Class.new(StandardError)
        attr_accessor :project, :sample, :key_update, :value_update, :metadata_update_params

        def initialize(project, sample, user = nil, params = {})
          super(user, params)
          @project = project
          @sample = sample
          @key_update = params['update_field']['key']
          @value_update = params['update_field']['value']
          @metadata_update_params = { 'metadata' => {} }
        end

        def execute
          authorize! @project, to: :update_sample?

          validate_sample_in_project

          validate_update_fields

          construct_metadata_update_params

          ::Samples::Metadata::UpdateService.new(@project, @sample, current_user, @metadata_update_params).execute
        rescue Samples::Metadata::Fields::UpdateService::SampleMetadataFieldsUpdateError => e
          @sample.errors.add(:base, e.message)
          @metadata_update_params
        end

        private

        def validate_sample_in_project
          return unless @project.id != @sample.project.id

          raise SampleMetadataFieldsUpdateError,
                I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project',
                       sample_name: @sample.name,
                       project_name: @project.name)
        end

        # Checks if neither key or value were changed
        def validate_update_fields
          return unless @key_update.keys[0] == @key_update.values[0] && @value_update.keys[0] == @value_update.values[0]

          raise SampleMetadataFieldsUpdateError,
                I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')
        end

        # Constructs the expected param for metadata update_service
        def construct_metadata_update_params
          if @key_update.keys[0] != @key_update.values[0]
            if validate_new_key
              raise SampleMetadataFieldsUpdateError,
                    I18n.t('services.samples.metadata.update_fields.key_exists', key: @key_update.values[0])
            end

            @metadata_update_params['metadata'][@key_update.keys[0]] = ''
          end

          @metadata_update_params['metadata'][@key_update.values[0]] = @value_update.values[0]
        end

        # Checks if the new key already exists within the @sample.metadata
        def validate_new_key
          key_exists = false
          @sample.metadata.each do |k, _v|
            if k.downcase == @key_update.values[0].downcase
              key_exists = true
              break
            end
          end
          key_exists
        end
      end
    end
  end
end
