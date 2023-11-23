# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService
      SampleMetadataUpdateError = Class.new(StandardError)
      attr_accessor :sample, :metadata, :metadata_key

      def initialize(sample, user = nil, params = {}, metadata = nil, metadata_key = nil) # rubocop:disable Metrics/ParameterLists
        super(user, params.except(:sample, :id))
        @sample = sample
        @metadata = metadata
        @metadata_key = metadata_key
      end

      def execute
        authorize! sample.project, to: :update_sample?

        @sample.metadata.merge(@metadata) if @metadata

        if @metadata_key
          raise SampleMetadataUpdateError, I18n.t('key_does_not_exist') unless @sample.metadata.key?(@metadata_key)

          @sample.metadata.delete(@metadata_key)
        end
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError
        @sample.errors.add(:base, e.message)
      end
    end
  end
end
