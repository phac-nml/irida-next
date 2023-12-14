# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService
      SampleMetadataUpdateError = Class.new(StandardError)
      attr_accessor :sample, :metadata, :analysis_id

      def initialize(project, sample, user = nil, params = {})
        super(user, params)
        @project = project
        @sample = sample
        @metadata = params['metadata']
        @analysis_id = params['analysis_id']
      end

      def execute
        authorize! sample.project, to: :update_sample?

        validate_sample_in_project

        validate_metadata_param

        transform_metadata_keys

        metadata_fields_update_status = metadata_modification

        @sample.save

        fields_not_updated(metadata_fields_update_status)
        metadata_fields_update_status
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.errors.add(:base, e.message)
        metadata_fields_update_status || nil
      end

      private

      def validate_sample_in_project
        return unless @project.id != @sample.project.id

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                    project_name: @project.name)
      end

      def validate_metadata_param
        return unless @metadata.nil? || @metadata == {}

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
      end

      def transform_metadata_keys
        # Without transforming keys, issues with overwritting can occur and multiples of the same key can appear
        @metadata = @metadata.transform_keys(&:to_s)
      end

      def metadata_modification
        update_status = { updated: [], not_updated: [] }
        @metadata.each do |key, value|
          if value.blank?
            if @sample['metadata'].key?(key)
              @sample['metadata'].delete(key)
              @sample['metadata_provenance'].delete(key)
              update_status[:updated].append(key)
            end
          else
            metadata_updated = assign_metadata_to_sample(key, value)
            metadata_updated ? update_status[:updated].append(key) : update_status[:not_updated].append(key)
          end
        end
        update_status
      end

      def assign_metadata_to_sample(key, value)
        # We don't overwrite existing @sample['metadata_provenance'] or @sample['metadata']
        # that has a {source: 'analysis'} with a user
        if @sample['metadata_provenance'].key?(key) && @analysis_id.nil? &&
           @sample['metadata_provenance'][key]['source'] == 'analysis'
          false
        else
          @sample['metadata_provenance'][key] =
            @analysis_id.nil? ? { source: 'user', id: current_user.id } : { source: 'analysis', id: @analysis_id }
          @sample['metadata'][key] = value
          true
        end
      end

      def fields_not_updated(metadata_fields_update_status)
        metadata_fields_not_updated = metadata_fields_update_status[:not_updated]
        return unless metadata_fields_not_updated.count.positive?

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.user_cannot_update_metadata',
                     sample_name: @sample.name,
                     metadata_fields: metadata_fields_not_updated.join(', '))
      end
    end
  end
end
