# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to Update multiple samples' metadata at a time. Currently used by metadata file import.
    class BulkUpdateService < BaseSampleMetadataUpdateService # rubocop:disable Metrics/ClassLength
      attr_accessor :namespace, :metadata_payload, :metadata_fields, :metadata_summary_data

      def initialize(namespace, metadata_payload, metadata_fields, user = nil, params = {})
        super(user, params)
        @namespace = namespace
        @metadata_payload = metadata_payload
        @metadata_fields = sanitize_metadata_fields(metadata_fields)
        @metadata_summary_data = {}
        @broadcast_target = params.key?(:broadcast_target) ? params[:broadcast_target] : nil
        @progress_bar_denominator = params.key?(:progress_bar_denominator) ? params[:progress_bar_denominator] : nil
      end

      def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        authorize! @namespace, to: :update_sample_metadata?
        activity_data = {}
        unsuccessful_updates = { not_updated: {}, unchanged: {} }
        successful_samples = []

        starting_index = 0
        should_update_progress_bar = false
        unless @broadcast_target.nil? && @progress_bar_denominator.nil?
          starting_index = (@progress_bar_denominator / 2) + 1
          should_update_progress_bar = true
        end

        @metadata_payload.each.with_index(starting_index) do |(sample_identifier, metadata), index| # rubocop:disable Metrics/BlockLength
          update_progress_bar(index, @progress_bar_denominator, @broadcast_target) if should_update_progress_bar
          next unless validate_metadata_param(metadata, sample_identifier)

          sample = find_sample(sample_identifier)
          next if sample.nil?

          project_puid = sample.project.puid
          metadata_changes = perform_metadata_update(sample, metadata, false)

          unless metadata_changes[:not_updated].empty?
            unsuccessful_updates[:not_updated][sample_identifier] =
              metadata_changes[:not_updated]
          end
          unless metadata_changes[:unchanged].empty?
            unsuccessful_updates[:unchanged][sample_identifier] =
              metadata_changes[:unchanged]
          end

          if metadata_changes[:added].empty? && metadata_changes[:deleted].empty? && metadata_changes[:updated].empty?
            next
          end

          successful_samples << sample_identifier
          if activity_data.key?(project_puid)
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

        handle_unsuccessful_updates(unsuccessful_updates)

        create_activities_and_update_metadata_summary(activity_data) unless activity_data.empty?
        successful_samples
      end

      private

      # occurs in this service as file import service requires unsanitized version for proper spreadsheet reading
      def sanitize_metadata_fields(metadata_fields)
        metadata_fields.map do |metadata_field|
          strip_whitespaces(metadata_field)
        end
      end

      def validate_metadata_param(metadata, sample_name) # rubocop:disable Naming/PredicateMethod
        return true if metadata.present?

        @namespace.errors.add(:sample, I18n.t('services.samples.metadata.empty_metadata', sample_name:))
        false
      end

      def validate_metadata_value(key, value, sample_name) # rubocop:disable Naming/PredicateMethod
        return true unless value.is_a?(Hash)

        @namespace.errors.add(:sample, I18n.t('services.samples.metadata.nested_metadata', sample_name:, key:))
        false
      end

      def find_sample(sample_identifier)
        id_type = determine_sample_identifier_type(sample_identifier)
        sample_identifier = parse_gid(sample_identifier) if id_type == 'gid'

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
        elsif sample_identifier.start_with?('gid://')
          'gid'
        else
          'name'
        end
      end

      def parse_gid(sample_identifier)
        IridaSchema.parse_gid(sample_identifier, { expected_type: Sample }).model_id
      rescue StandardError => e
        Rails.logger.error "An error occurred: #{e.message}"
      end

      def query_group_samples(id_type, sample_identifier)
        scope_args = if id_type == 'puid'
                       { puid: sample_identifier }
                     elsif %w[id gid].include?(id_type)
                       { id: sample_identifier }
                     else
                       { name: sample_identifier }
                     end
        sample = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                          scope_options: { namespace: @namespace,
                                                           minimum_access_level: Member::AccessLevel::MAINTAINER })
                 .where(scope_args)

        return sample.first unless sample.count != 1

        add_group_sample_query_error(sample, sample_identifier)
        nil
      end

      def query_project_samples(id_type, sample_identifier)
        project = @namespace.project
        sample = if id_type == 'puid'
                   Sample.find_by(puid: sample_identifier, project_id: project.id)
                 elsif %w[id gid].include?(id_type)
                   Sample.find_by(id: sample_identifier, project_id: project.id)
                 else
                   Sample.find_by(name: sample_identifier, project_id: project.id)
                 end
        return sample unless sample.nil?

        @namespace.errors.add(:sample,
                              I18n.t('services.samples.metadata.bulk_update.sample_not_found',
                                     sample_identifier:))
        nil
      end

      def add_group_sample_query_error(sample, sample_identifier)
        error_key = sample.none? ? 'sample_not_found' : 'duplicate_identifier'
        @namespace.errors.add(:sample, I18n.t("services.samples.metadata.bulk_update.#{error_key}", sample_identifier:))
      end

      def create_activities_and_update_metadata_summary(activity_data)
        if @namespace.group_namespace?
          create_group_activity(activity_data)
        else
          create_project_activity_and_update_metadata_summary(@namespace.puid, activity_data[@namespace.puid])
        end
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

        activity = @namespace.create_activity key: 'group.samples.bulk_metadata_update',
                                              owner: current_user,
                                              parameters:
                                              {
                                                imported_metadata_samples_count: group_sample_count,
                                                action: 'group_bulk_metadata_update'
                                              }
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_bulk_metadata_update')
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

        activity = project_namespace.create_activity key: 'namespaces_project_namespace.samples.bulk_metadata_update',
                                                     owner: current_user,
                                                     parameters:
                                                     {
                                                       imported_metadata_samples_count: sample_data.count,
                                                       action: 'project_bulk_metadata_update'
                                                     }
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'project_bulk_metadata_update')
        update_namespace_metadata_summary(project_namespace,
                                          @metadata_summary_data[project_puid][:deleted],
                                          @metadata_summary_data[project_puid][:added],
                                          false)
      end

      def handle_unsuccessful_updates(unsuccessful_updates)
        unsuccessful_updates.each do |key, updates|
          updates.each do |sample_identifier, fields|
            @namespace.errors.add(:sample,
                                  I18n.t("services.samples.metadata.bulk_update.sample_metadata_fields_#{key}",
                                         sample_name: sample_identifier,
                                         metadata_fields: fields.join(', ')))
          end
        end
      end

      def add_changes_to_metadata_summary(project_puid, metadata_changes)
        initialize_metadata_summary_data_for_project(project_puid) unless @metadata_summary_data.key?(project_puid)
        update_tracked_metadata_summary_changes(project_puid, metadata_changes)
      end

      def initialize_metadata_summary_data_for_project(project_puid)
        @metadata_summary_data[project_puid] = { added: {}, deleted: {} }
        @metadata_fields.each do |metadata_field|
          downcased_metadata_field = metadata_field.downcase
          @metadata_summary_data[project_puid][:added][downcased_metadata_field] = 0
          @metadata_summary_data[project_puid][:deleted][downcased_metadata_field] = 0
        end
      end

      def update_tracked_metadata_summary_changes(project_puid, metadata_changes)
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
    end
  end
end
