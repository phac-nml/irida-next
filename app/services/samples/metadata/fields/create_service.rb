# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to validate the create_fields param and construct the metadata update param to be passed
      # to Samples::Metadata::UpdateService
      class CreateService < BaseService
        SampleMetadataFieldsCreateError = Class.new(StandardError)
        attr_accessor :project, :sample, :create_fields, :metadata_update_params, :token

        def initialize(project, sample, user = nil, create_fields = {})
          super(user, params)
          @project = project
          @sample = sample
          @create_fields = create_fields
          @token = create_fields.delete(:token)
          @metadata_update_params = { 'metadata' => {}, 'existing_keys' => [] }
        end

        def execute
          authorize! @project, to: :update_sample?,
                               context: { token: }

          validate_sample_in_project

          construct_metadata_update_params

          validate_new_added_keys

          updated_metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                           @metadata_update_params).execute

          { added_keys: updated_metadata_fields[:added],
            existing_keys: @metadata_update_params['existing_keys'] }
        rescue Samples::Metadata::Fields::CreateService::SampleMetadataFieldsCreateError => e
          @sample.errors.add(:base, e.message)
          @metadata_update_params
        end

        private

        def validate_sample_in_project
          return unless @project.id != @sample.project.id

          raise SampleMetadataFieldsCreateError,
                I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project',
                       sample_name: @sample.name, project_name: @project.name)
        end

        # Constructs the expected param for metadata update_service
        def construct_metadata_update_params
          @create_fields.each do |k, v|
            if @sample.metadata.transform_keys(&:downcase).key?(k.downcase)
              @metadata_update_params['existing_keys'] << k
            else
              @metadata_update_params['metadata'][k] = v
            end
          end
        end

        # Checks if all new keys already exist
        def validate_new_added_keys
          return unless @metadata_update_params['metadata'].empty?

          if @metadata_update_params['existing_keys'].count == 1
            raise SampleMetadataFieldsCreateError,
                  I18n.t('services.samples.metadata.fields.single_all_keys_exist',
                         key: @metadata_update_params['existing_keys'][0])
          else
            raise SampleMetadataFieldsCreateError,
                  I18n.t('services.samples.metadata.fields.multi_all_keys_exist',
                         keys: @metadata_update_params['existing_keys'].join(', '))
          end
        end
      end
    end
  end
end
