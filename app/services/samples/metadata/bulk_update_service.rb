# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update Samples::Metadata
    class BulkUpdateService < BaseSampleMetadataUpdateService # rubocop:disable Metrics/ClassLength
      attr_accessor :namespace, :metadata_payload

      def initialize(namespace, metadata_payload, metadata_fields, user = nil, params = {})
        super(user, params)
        @namespace = namespace
        @metadata_payload = metadata_payload
        @metadata_fields = metadata_fields
        @metadata_summary_data = {}
      end

      def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        activity_data = {}
        unsuccessful_updates = {}
        @metadata_payload.each do |sample_identifier, metadata|
          sample = find_sample(sample_identifier)
          next if sample.nil?

          project_puid = sample.project.puid
          metadata_changes = perform_metadata_update(sample, metadata)

          if !metadata_changes[:not_updated].empty?
            unsuccessful_updates[sample_identifier] = metadata_changes[:not_updated]
          elsif activity_data.key?(project_puid)
            activity_data[project_puid] << { sample_puid: sample.puid, sample_name: sample.name,
                                             project_name: sample.project.name,
                                             project_puid: }
          else
            activity_data[project_puid] = [{ sample_puid: sample.puid, sample_name: sample.name,
                                             project_name: sample.project.name,
                                             project_puid: }]
          end

          add_changes_to_metadata_summary(project_puid, metadata_changes)
        end
        unless unsuccessful_updates.empty?
          unsuccessful_updates.each do |sample_identifier, changes|
            @namespace.errors.add(:sample,
                                  I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                                         sample_name: sample_identifier,
                                         metadata_fields: changes.join(', ')))
          end
        end

        if @namespace.group_namespace?
          create_group_activity(activity_data)
        else
          create_project_activity_and_update_metadata_summary(@namespace.puid, activity_data[@namespace.puid])
        end

        activity_data
      end

      private

      def find_sample(sample_identifier)
        id_type = determine_sample_identifier_type(sample_identifier)
        if @namespace.group_namespace?
          query_group_samples(id_type, sample_identifier)
        else
          query_project_samples(id_type, sample_identifier)
        end
      end

      def determine_sample_identifier_type(sample_identifier)
        if Irida::PersistentUniqueId.valid_puid?(sample_identifier, Sample)
          'puid'
        elsif sample_identifier.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
          'id'
        else
          'name'
        end
      end

      def query_group_samples(id_type, sample_identifier)
        scope = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                         scope_options: { namespace: @namespace,
                                                          minimum_access_level: Member::AccessLevel::MAINTAINER })
        if id_type == 'puid'
          scope.find_by(puid: sample_identifier)
        elsif id_type == 'id'
          scope.find_by(id: sample_identifier)
        else
          sample = scope.where(name: sample_identifier)
          return sample.first unless sample.count != 1

          add_sample_query_error(sample.none? ? 'sample_not_found' : 'duplicate_identifier', sample_identifier)
          nil
        end
      end

      def query_project_samples(id_type, sample_identifier)
        project = @namespace.project
        if id_type == 'puid'
          Sample.find_by(puid: sample_identifier, project_id: project.id)
        elsif id_type == 'id'
          Sample.find_by(id: sample_identifier, project_id: project.id)
        else
          sample = Sample.where(name: sample_identifier, project_id: project.id)
          return sample.first unless sample.count != 1

          add_sample_query_error(sample.none? ? 'sample_not_found' : 'duplicate_identifier', sample_identifier)
          nil
        end
      end

      def add_sample_query_error(error_key, sample_identifier)
        @namespace.errors.add(
          :sample,
          I18n.t(
            "services.samples.metadata.bulk_update.#{error_key}",
            sample_identifier:
          )
        )
      end

      def create_group_activity(activity_data) # rubocop:disable Metrics/MethodLength
        group_sample_count = 0
        group_data = []
        activity_data.each do |project_puid, sample_data|
          create_project_activity_and_update_metadata_summary(project_puid, sample_data)
          group_sample_count += sample_data.count
          group_data << sample_data
        end
        ext_details = ExtendedDetail.create!(details: {
                                               imported_metadata_samples_count:
                                               group_sample_count,
                                               samples_imported_metadata_data: group_data.flatten
                                             })

        activity = @namespace.create_activity key: 'group.samples.import_metadata',
                                              owner: current_user,
                                              parameters:
                                              {
                                                imported_metadata_samples_count: group_sample_count,
                                                action: 'group_import_metadata'
                                              }
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_import_metadata')
      end

      def create_project_activity_and_update_metadata_summary(project_puid, sample_data) # rubocop:disable Metrics/MethodLength
        project_namespace = if @namespace.group_namespace?
                              Namespaces::ProjectNamespace.find_by(puid: project_puid)
                            else
                              @namespace
                            end

        ext_details = ExtendedDetail.create!(details: {
                                               imported_metadata_samples_count: sample_data.count,
                                               samples_imported_metadata_data: sample_data
                                             })

        activity = project_namespace.create_activity key: 'namespaces_project_namespace.samples.import_metadata',
                                                     owner: current_user,
                                                     parameters:
                                                     {
                                                       imported_metadata_samples_count: sample_data.count,
                                                       action: 'project_import_metadata'
                                                     }
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'project_import_metadata')

        update_metadata_summary(project_namespace)
      end

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

      def add_changes_to_metadata_summary(project_puid, metadata_changes)
        initialize_metadata_summary_data(project_puid) unless @metadata_summary_data.key?(project_puid)
        execute_metadata_changes(project_puid, metadata_changes)
      end

      def initialize_metadata_summary_data(project_puid)
        @metadata_summary_data[project_puid] = { added: {}, deleted: {} }
        @metadata_fields.each do |metadata_field|
          @metadata_summary_data[project_puid][:added][metadata_field] = 0
          @metadata_summary_data[project_puid][:deleted][metadata_field] = 0
        end
      end

      def execute_metadata_changes(project_puid, metadata_changes)
        unless metadata_changes[:added].empty?
          metadata_changes[:added].each do |added_metadata|
            @metadata_summary_data[project_puid][:added][added_metadata] += 1
          end
        end

        return if metadata_changes[:deleted].empty?

        metadata_changes[:deleted].each do |deleted_metadata|
          @metadata_summary_data[project_puid][:deleted][deleted_metadata] += 1
        end
      end

      def update_metadata_summary(project_namespace)
        namespace_puid = project_namespace.puid

        project_namespace.update_metadata_summary_by_update_service(@metadata_summary_data[namespace_puid][:deleted],
                                                                    @metadata_summary_data[namespace_puid][:added],
                                                                    false)
      end
    end
  end
end
