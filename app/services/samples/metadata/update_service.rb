# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService
      SampleMetadataUpdateError = Class.new(StandardError)
      attr_accessor :sample, :metadata, :metadata_key

      def initialize(project, sample, user = nil, params = {}, metadata = nil, metadata_key = nil) # rubocop:disable Metrics/ParameterLists
        super(user, params.except(:sample, :id))
        @project = project
        @sample = sample
        @metadata = metadata
        @metadata_key = metadata_key
      end

      def execute # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        authorize! sample.project, to: :update_sample?

        if @project.id != @sample.project.id
          raise SampleMetadataUpdateError,
                I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                      project_name: @project.name)
        end

        if @metadata
          @metadata = @metadata.transform_keys(&:to_s)
          @sample['metadata'] = @sample['metadata'].merge(@metadata)
        end

        if @metadata_key
          unless @sample['metadata'].key?(@metadata_key)
            raise SampleMetadataUpdateError,
                  I18n.t('services.samples.metadata.key_does_not_exist', sample_name: @sample.name, key: @metadata_key)
          end
          @sample['metadata'].delete(@metadata_key)
        end
        @sample.update(id: @sample.id)
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.errors.add(:base, e.message)
      end
    end
  end
end
