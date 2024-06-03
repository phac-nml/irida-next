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
        @metadata_changes = { added: [], updated: [], deleted: [], not_updated: [] }
      end

      def execute
        authorize! sample.project, to: :update_sample?,
                                   context: { token: current_user.personal_access_tokens&.active&.write_access&.last }

        validate_sample_in_project

        validate_metadata_param

        transform_metadata_keys

        @sample.with_lock do
          perform_metadata_update
          @sample.save
        end

        update_metadata_summary

        handle_not_updated_fields
        @metadata_changes
      rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        @sample.errors.add(:base, e.message)
        @metadata_changes
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

      def perform_metadata_update
        @metadata.each do |key, value|
          if value.blank?
            if @sample.metadata.key?(key)
              @sample.metadata.delete(key)
              @sample.metadata_provenance.delete(key)
              @metadata_changes[:deleted] << key
            end
          else
            assign_metadata_to_sample(key, value)
          end
        end
      end

      def assign_metadata_to_sample(key, value) # rubocop:disable Metrics/AbcSize
        # We don't overwrite existing @sample.metadata_provenance or @sample.metadata
        # that has a {source: 'analysis'} with a user
        if @sample.metadata_provenance.key?(key) && @analysis_id.nil? &&
           @sample.metadata_provenance[key]['source'] == 'analysis'
          @metadata_changes[:not_updated] << key
        else
          @sample.metadata.key?(key) ? @metadata_changes[:updated] << key : @metadata_changes[:added] << key
          @sample.metadata_provenance[key] =
            if @analysis_id.nil?
              { source: 'user', id: current_user.id, updated_at: Time.current }
            else
              { source: 'analysis', id: @analysis_id, updated_at: Time.current }
            end
          @sample.metadata[key] = value
        end
      end

      # Metadata fields that were not updated due to a user trying to overwrite metadata previously added by an
      # analysis in assign_metadata_to_sample are handled here, where they are assigned to the @sample.error
      # and will be used for a :error flash message in the UI.
      def handle_not_updated_fields
        metadata_fields_not_updated = @metadata_changes[:not_updated]
        return unless metadata_fields_not_updated.count.positive?

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.user_cannot_update_metadata',
                     sample_name: @sample.name, metadata_fields: metadata_fields_not_updated.join(', '))
      end

      def update_metadata_summary
        return unless @metadata_changes[:added].count.positive? || @metadata_changes[:deleted].count.positive?

        @project.namespace.update_metadata_summary_by_update_service(@metadata_changes[:deleted],
                                                                     @metadata_changes[:added])
      end
    end
  end
end
