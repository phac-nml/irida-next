# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class BulkUpdateService < BaseSampleMetadataUpdateService # rubocop:disable Metrics/ClassLength
      attr_accessor :namespace, :metadata_payload

      def initialize(namespace, metadata_payload, user = nil, params = {})
        super(user, params)
        @namespace = namespace
        @metadata_payload = metadata_payload
        @include_activity = params['include_activity']
      end

      def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        # authorize user can update at the namespace level
        successful_updates = {}
        unsuccessful_updates = {}
        @metadata_payload.each do |sample_id, metadata|
          sample = find_sample(sample_id)
          next if sample.nil?

          # authorize user can update at the sample level
          sample.with_lock do
            @metadata_change = perform_metadata_update(sample, metadata)
            sample.save
          end
          if !@metadata_change[:not_updated].empty?
            unsuccessful_updates[sample_id] = @metadata_change[:not_updated]
          elsif @namespace.group_namespace?
            if successful_updates.key?(sample.project.puid)
              successful_updates[sample.project.puid].merge({ sample.puid => @metadata_change })
            else
              successful_updates.merge({ sample.puid => @metadata_change })
            end
          else
            successful_updates.merge({ sample.puid => @metadata_change })
          end
        end
        unless unsuccessful_updates.empty?
          unsuccessful_updates.each do |sample_id, changes|
            @namespace.errors.add(:sample,
                                  I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                                         sample_name: sample_id,
                                         metadata_fields: changes.join(', ')))
          end
        end

        # if @include_activity && @namespace.group_namespace?

        # end

        successful_updates
        # if @include_activity
        #   @project.namespace.create_activity key: 'namespaces_project_namespace.samples.metadata.update',
        #                                      owner: current_user,
        #                                      parameters:
        #                                       {
        #                                         sample_id: @sample.id,
        #                                         sample_puid: @sample.puid,
        #                                         action: 'metadata_update'
        #                                       }
        # end

        #   update_metadata_summary

        #   handle_not_updated_fields

        #   @metadata_changes
        # rescue Samples::Metadata::UpdateService::SampleMetadataUpdateValidationError => e
        #   @sample.reload.errors.add(:base, e.message)
        #   { added: [], updated: [], deleted: [], not_updated: @metadata.nil? ? [] : @metadata.keys, unchanged: [] }
        # rescue Samples::Metadata::UpdateService::SampleMetadataUpdateError => e
        #   @sample.reload.errors.add(:base, e.message)
        #   @metadata_changes
      end

      private

      def find_sample(sample_id)
        id_type = determine_sample_id_type(sample_id)
        if @namespace.group_namespace?
          query_group_samples(id_type, sample_id)
        else
          query_project_samples(id_type, sample_id)
        end
      end

      def determine_sample_id_type(sample_id)
        if Irida::PersistentUniqueId.valid_puid?(sample_id, Sample)
          'puid'
        elsif sample_id.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
          'id'
        else
          'name'
        end
      end

      def query_group_samples(id_type, sample_id)
        scope = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                         scope_options: { namespace: @namespace,
                                                          minimum_access_level: Member::AccessLevel::MAINTAINER })
        if id_type == 'puid'
          scope.find_by(puid: sample_id)
        elsif id_type == 'id'
          scope.find_by(id: sample_id)
        else
          sample = scope.where(name: sample_id)
          return sample.first unless sample.count != 1

          add_sample_query_error(sample.none? ? 'sample_not_found' : 'duplicate_identifier', sample_id)
          nil
        end
      end

      def query_project_samples(id_type, sample_id)
        project = @namespace.project
        if id_type == 'puid'
          Sample.find_by(puid: sample_id, project_id: project.id)
        elsif id_type == 'id'
          Sample.find_by(id: sample_id, project_id: project.id)
        else
          sample = Sample.where(name: sample_id, project_id: project.id)
          return sample.first unless sample.count != 1

          add_sample_query_error(sample.none? ? 'sample_not_found' : 'duplicate_identifier', sample_id)
          nil
        end
      end

      def add_sample_query_error(error_key, sample_id)
        @namespace.errors.add(
          :sample,
          I18n.t(
            "services.samples.metadata.bulk_update.#{error_key}",
            sample_identifier: sample_id
          )
        )
      end
      # def perform_metadata_update
      #   @metadata.each do |key, value|
      #     validate_metadata_value(key, value)

      #     key = strip_whitespaces(key.to_s.downcase)
      #     value = strip_whitespaces(value.to_s) # remove data types
      #     status = get_metadata_change_status(key, value)
      #     next unless status

      #     @metadata_changes[status] << key
      #     if %i[updated added].include?(status)
      #       add_metadata_to_sample(key, value)
      #     elsif status == :deleted
      #       remove_metadata_from_sample(key)
      #     end
      #   end
      # end

      # def remove_metadata_from_sample(key)
      #   @sample.metadata.delete(key)
      #   @sample.metadata_provenance.delete(key)
      # end

      # def add_metadata_to_sample(key, value)
      #   @sample.metadata_provenance[key] =
      #     if @analysis_id.nil?
      #       { source: 'user', id: current_user.id, updated_at: Time.current }
      #     else
      #       { source: 'analysis', id: @analysis_id, updated_at: Time.current }
      #     end
      #   @sample.metadata[key] = value
      # end

      # def get_metadata_change_status(key, value)
      #   if value.blank?
      #     :deleted if @sample.field?(key)
      #   elsif @sample.metadata_provenance.key?(key) && @analysis_id.nil? &&
      #         @sample.metadata_provenance[key]['source'] == 'analysis'
      #     :not_updated
      #   elsif @sample.field?(key) && @sample.metadata[key] == value
      #     @force_update ? :updated : :unchanged
      #   else
      #     @sample.field?(key) ? :updated : :added
      #   end
      # end

      # Metadata fields that were not updated due to a user trying to overwrite metadata previously added by an
      # analysis in assign_metadata_to_sample are handled here, where they are assigned to the @sample.error
      # and will be used for a :error flash message in the UI.
      def handle_not_updated_fields
        metadata_fields_not_updated = @metadata_changes[:not_updated]
        return unless metadata_fields_not_updated.any?

        raise SampleMetadataUpdateError,
              I18n.t('services.samples.metadata.user_cannot_update_metadata',
                     sample_name: @sample.name, metadata_fields: metadata_fields_not_updated.join(', '))
      end

      def update_metadata_summary
        return unless @metadata_changes[:added].any? || @metadata_changes[:deleted].any?

        @project.namespace.update_metadata_summary_by_update_service(@metadata_changes[:deleted],
                                                                     @metadata_changes[:added])
      end
    end
  end
end
