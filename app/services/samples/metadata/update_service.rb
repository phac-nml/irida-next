# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService
      SampleMetadataUpdateError = Class.new(StandardError)
      attr_accessor :sample, :metadata, :analysis_id

      def initialize(project, sample, user = nil, params = {}, metadata = nil, analysis_id = nil) # rubocop:disable Metrics/ParameterLists
        super(user, params)
        @project = project
        @sample = sample
        @metadata = metadata
        @analysis_id = analysis_id
      end

      def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        authorize! sample.project, to: :update_sample?

        if @project.id != @sample.project.id
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                      project_name: @project.name)
        end

        if @metadata
          @metadata = @metadata.transform_keys(&:to_s)
          @metadata.each do |k, v|
            if v.blank?
              @sample['metadata'].delete(k) && @sample['metadata_provenance'].delete(k) if @sample['metadata'].key?(k)
            else
              @sample['metadata'][k] = v
              @sample['metadata_provenance'][k] =
                @analysis_id.nil? ? { source: 'user', id: current_user.id } : { source: 'analysis', id: @analysis_id }
            end
          end
        else
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
        end

        @sample.update(id: @sample.id)
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.errors.add(:base, e.message)
      end
    end
  end
end
