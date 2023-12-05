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

      def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        authorize! sample.project, to: :update_sample?

        if @project.id != @sample.project.id
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                      project_name: @project.name)
        end

        if @metadata
          # Without transforming keys, issues with overwritting can occur and multiples of the same key can appear
          @metadata = @metadata.transform_keys(&:to_s)
          metadata_fields_not_updated = []
          @metadata.each do |key, value|
            if value.blank?
              if @sample['metadata'].key?(key)
                @sample['metadata'].delete(key) && @sample['metadata_provenance'].delete(key)
              end
            else
              provenance_updated = update_metadata_provenance(key)
              if provenance_updated
                assign_metadata_value(key, value)
              else
                metadata_fields_not_updated.append("#{key}: #{value}")
              end
            end
          end
          @sample.update(id: @sample.id)
        else
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
        end

        if metadata_fields_not_updated.count.positive?
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.user_cannot_update_metadata',
                       sample_name: @sample.name,
                       metadata_fields: metadata_fields_not_updated.join(', '))
        end
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.errors.add(:base, e.message)
      end

      private

      def update_metadata_provenance(key) # rubocop:disable Metrics/MethodLength
        if @sample['metadata_provenance'].key?(key)
          # We don't overwrite existing @sample['metadata_provenance'] or @sample['metadata']
          # that has a {source: 'analysis'} with a user
          if @analysis_id.nil?
            if @sample['metadata_provenance'][key]['source'] == 'user'
              @sample['metadata_provenance'][key] = { source: 'user', id: current_user.id }
              true
            else
              false
            end
          else
            @sample['metadata_provenance'][key] = { source: 'analysis', id: @analysis_id }
            true
          end
        else
          @sample['metadata_provenance'][key] =
            @analysis_id.nil? ? { source: 'user', id: current_user.id } : { source: 'analysis', id: @analysis_id }
          true
        end
      end

      def assign_metadata_value(key, value)
        @sample['metadata'][key] = value
      end
    end
  end
end
