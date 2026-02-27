# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseSampleMetadataUpdateService
      class SampleMetadataUpdateError < StandardError
      end

      class SampleMetadataUpdateValidationError < StandardError
      end

      class SampleMetadataKeyValidationError < StandardError
      end
      attr_accessor :sample, :metadata, :analysis_id

      def initialize(project, sample, user = nil, params = {})
        super(user, params)
        @project = project
        @sample = sample
        @metadata = params['metadata']
        @analysis_id = params['analysis_id']
        @include_activity = params.key?(:include_activity) ? params[:include_activity] : true
        @force_update = params.key?('force_update') ? params['force_update'] : false
      end

      def execute # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        authorize! sample.project, to: :update_sample?

        validate_sample_in_project

        validate_metadata_param

        @metadata_changes = perform_metadata_update(@sample, @metadata, @force_update)

        if @include_activity && (@metadata_changes[:deleted].any? || @metadata_changes[:added].any?)
          @project.namespace.create_activity key: 'namespaces_project_namespace.samples.metadata.update',
                                             owner: current_user,
                                             parameters:
                                              {
                                                sample_id: @sample.id,
                                                sample_puid: @sample.puid,
                                                action: 'metadata_update'
                                              }
        end

        update_namespace_metadata_summary(@project.namespace, @metadata_changes[:deleted], @metadata_changes[:added],
                                          true)

        handle_not_updated_fields if @metadata_changes[:not_updated].any?

        @metadata_changes
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateValidationError => e
        @sample.reload.errors.add(:base, e.message)
        { added: [], updated: [], deleted: [], not_updated: @metadata.nil? ? [] : @metadata.keys, unchanged: [] }
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.reload.errors.add(:base, e.message)
        @metadata_changes
      end

      private

      def validate_sample_in_project
        return true unless @project.id != @sample.project.id

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                    project_name: @project.name)
      end

      def validate_metadata_param
        return if @metadata.present?

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
      end

      def validate_metadata_value(key, value, sample_name)
        return unless value.is_a?(Hash)

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.nested_metadata', sample_name:, key:)
      end

      # Metadata fields that were not updated due to a user trying to overwrite metadata previously added by an
      # analysis in assign_metadata_to_sample are handled here, where they are assigned to the @sample.error
      # and will be used for a :error flash message in the UI.
      def handle_not_updated_fields
        metadata_fields_not_updated = @metadata_changes[:not_updated]

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.user_cannot_update_metadata',
                     sample_name: @sample.name, metadata_fields: metadata_fields_not_updated.join(', '))
      end

      def update_metadata_summary
        return unless @metadata_changes[:added].any? || @metadata_changes[:deleted].any?

        @project.namespace.update_metadata_summary_by_update_service(@metadata_changes[:deleted],
                                                                     @metadata_changes[:added], true)
      end
    end
  end
end
