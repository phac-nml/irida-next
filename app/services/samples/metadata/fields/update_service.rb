# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to validate the update_fields param and construct the metadata update param to be passed
      # to metadata_controller#update and Samples::Metadata::UpdateService
      class UpdateService < BaseService
        class SampleMetadataFieldsUpdateError < StandardError
        end

        class SampleMetadataKeyValidationError < StandardError
        end

        class SampleMetadataValueValidationError < StandardError
        end
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
        rescue Samples::Metadata::Fields::UpdateService::SampleMetadataKeyValidationError => e
          @sample.reload.errors.add(:key, e.message)
        rescue Samples::Metadata::Fields::UpdateService::SampleMetadataValueValidationError => e
          @sample.reload.errors.add(:value, e.message)
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
        def validate_update_fields # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          if @key_update.keys[0] == strip_whitespaces(@key_update.values[0]) &&
             @value_update.keys[0] == strip_whitespaces(@value_update.values[0])

            raise SampleMetadataFieldsUpdateError,
                  I18n.t('services.samples.metadata.update_fields.metadata_was_not_changed')
          end

          if @key_update.values[0].blank?
            raise SampleMetadataKeyValidationError, I18n.t('services.samples.metadata.update_fields.key_required')
          end

          if @value_update.values[0].blank?
            raise SampleMetadataValueValidationError,
                  I18n.t('services.samples.metadata.update_fields.value_required')
          end

          return unless @sample.metadata_provenance[@key_update.keys[0]]['source'] == 'analysis'

          raise SampleMetadataFieldsUpdateError,
                I18n.t('services.samples.metadata.update_fields.user_cannot_edit_metadata_key',
                       key: @key_update.keys[0])
        end

        # Constructs the expected param for metadata update_service
        def construct_metadata_update_params # rubocop:disable Metrics/AbcSize
          if @key_update.keys[0] != @key_update.values[0]
            if @sample.metadata.transform_keys(&:downcase).key?(@key_update.values[0].downcase)
              raise SampleMetadataFieldsUpdateError,
                    I18n.t('services.samples.metadata.update_fields.key_exists', key: @key_update.values[0])
            end
            @metadata_update_params['metadata'][@key_update.keys[0]] = ''
          end
          @metadata_update_params['metadata'][@key_update.values[0]] = @value_update.values[0]
        end
      end
    end
  end
end
