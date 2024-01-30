# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to validate the edit_fields param and construct the metadata update param to be passed
      # to metadata_controller#update and Samples::Metadata::UpdateService
      class EditService < BaseService
        SampleMetadataFieldsEditError = Class.new(StandardError)
        attr_accessor :project, :sample, :edit_fields

        def initialize(project, sample, user = nil, params = {})
          super(user, params)
          @project = project
          @sample = sample
          @key_edit = params['edit_field']['key']
          @value_edit = params['edit_field']['value']
          @metadata_update_params = {}
        end

        def execute
          authorize! @project, to: :update_sample?

          validate_sample_in_project

          validate_edit_fields

          construct_metadata_update_params
        rescue Samples::Metadata::Fields::EditService::SampleMetadataFieldsEditError => e
          @sample.errors.add(:base, e.message)
          @metadata_update_params
        end

        private

        def validate_sample_in_project
          return unless @project.id != @sample.project.id

          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project',
                       sample_name: @sample.name,
                       project_name: @project.name)
        end

        # Checks if neither key or value were changed
        def validate_edit_fields
          return unless @key_edit.keys[0] == @key_edit.values[0] && @value_edit.keys[0] == @value_edit.values[0]

          raise SampleMetadataFieldsEditError, I18n.t('services.samples.metadata.edit_fields.metadata_was_not_changed')
        end

        # Constructs the expected param for metadata update_service
        def construct_metadata_update_params
          metadata_update_params = { metadata: {} }
          if @key_edit.keys[0] != @key_edit.values[0]
            if validate_new_key
              raise SampleMetadataFieldsEditError,
                    I18n.t('services.samples.metadata.edit_fields.key_exists', key: @key_edit.values[0])
            end

            metadata_update_params[:metadata][@key_edit.keys[0]] = ''
          end

          metadata_update_params[:metadata][@key_edit.values[0]] = @value_edit.values[0]
          metadata_update_params
        end

        # Checks if the new key already exists within the @sample.metadata
        def validate_new_key
          key_exists = false
          @sample.metadata.each do |k, _v|
            if k.downcase == @key_edit.values[0].downcase
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
