# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class UpdateService < BaseService # rubocop:disable Metrics/ClassLength
      SampleMetadataUpdateError = Class.new(StandardError)
      SampleMetadataUpdateValidationError = Class.new(StandardError)
      attr_accessor :sample, :metadata, :analysis_id

      def initialize(project, sample, user = nil, params = {})
        super(user, params)
        @project = project
        @sample = sample
        @metadata = params['metadata']
        @analysis_id = params['analysis_id']
        @metadata_changes = { added: [], updated: [], deleted: [], not_updated: [], unchanged: [] }
        @include_activity = params.key?('include_activity') ? params['include_activity'] : true
      end

      def execute # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        authorize! sample.project, to: :update_sample?

        validate_sample_in_project

        validate_metadata_param

        @sample.with_lock do
          perform_metadata_update
          @sample.save
        end

        if @include_activity
          @project.namespace.create_activity key: 'namespaces_project_namespace.samples.metadata.update',
                                             owner: current_user,
                                             parameters:
                                              {
                                                sample_id: @sample.id,
                                                sample_puid: @sample.puid,
                                                action: 'metadata_update'
                                              }
        end

        update_metadata_summary

        handle_not_updated_fields

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
        return unless @project.id != @sample.project.id

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                    project_name: @project.name)
      end

      def validate_metadata_param
        return unless @metadata.nil? || @metadata == {}

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
      end

      def validate_metadata_value(key, value)
        return unless value.is_a?(Hash)

        raise SampleMetadataUpdateValidationError,
              I18n.t('services.samples.metadata.nested_metadata', sample_name: @sample.name, key:)
      end

      def perform_metadata_update
        @metadata.each do |key, value|
          validate_metadata_value(key, value)

          key = key.to_s.downcase.strip
          value = value.to_s.strip # remove data types

          status = get_metadata_change_status(key, value)
          next unless status

          @metadata_changes[status] << key
          if %i[updated added].include?(status)
            add_metadata_to_sample(key, value)
          elsif status == :deleted
            remove_metadata_from_sample(key)
          end
        end
      end

      def remove_metadata_from_sample(key)
        @sample.metadata.delete(key)
        @sample.metadata_provenance.delete(key)
      end

      def add_metadata_to_sample(key, value)
        @sample.metadata_provenance[key] =
          if @analysis_id.nil?
            { source: 'user', id: current_user.id, updated_at: Time.current }
          else
            { source: 'analysis', id: @analysis_id, updated_at: Time.current }
          end
        @sample.metadata[key] = value
      end

      def get_metadata_change_status(key, value) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if value.blank?
          :deleted if @sample.metadata.key?(key)
        elsif @sample.metadata_provenance.key?(key) && @analysis_id.nil? &&
              @sample.metadata_provenance[key]['source'] == 'analysis'
          :not_updated
        elsif @sample.metadata.key?(key) && @sample.metadata[key] == value
          :unchanged
        else
          @sample.metadata.key?(key) ? :updated : :added
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
