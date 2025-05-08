# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering extended details list items
    class ActivityListDialogComponent < Component
      attr_accessor :activity, :activity_owner, :activity_type

      def initialize(activity: nil, activity_owner: nil)
        @activity = activity
        @activity[:parameters] = @activity.parameters.transform_keys(&:to_sym)
        @extended_details = activity.extended_details
        @activity_owner = activity_owner
        @activity_type = @activity.parameters[:action]
        set_additional_params
        set_pagination_aria_labels
      end

      # @title, @description, and @data are all required attributes
      def set_additional_params # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        case @activity_type
        when 'sample_transfer'
          project_type = @activity.parameters[:source_project].present? ? 'source' : 'target'

          @title = I18n.t(:'components.activity.dialog.sample_transfer.title')

          @description = if project_type == 'source'
                           I18n.t(
                             :'components.activity.dialog.sample_transfer.source_project_description',
                             user: @activity_owner,
                             count: @activity.parameters[:transferred_samples_count],
                             source_project_puid: @activity.parameters[:source_project_puid]
                           )
                         else
                           I18n.t(
                             :'components.activity.dialog.sample_transfer.target_project_description',
                             user: @activity_owner,
                             count: @activity.parameters[:transferred_samples_count],
                             target_project_puid: @activity.parameters[:target_project_puid]
                           )
                         end

          @data = @extended_details.details['transferred_samples_data'].to_json

        when 'sample_destroy_multiple'
          @title = I18n.t(:'components.activity.dialog.sample_destroy.title')
          @description = I18n.t(:'components.activity.dialog.sample_destroy.description',
                                user: @activity_owner,
                                count: @activity.parameters[:samples_deleted_count])
          @data = @extended_details.details['deleted_samples_data'].to_json

        when 'project_import_samples'
          @title = I18n.t(:'components.activity.dialog.import_samples.title')
          @description = I18n.t('components.activity.dialog.import_samples.description.project',
                                user: @activity_owner,
                                count: @activity.parameters[:imported_samples_count])
          @data = @extended_details.details['imported_samples_data'].to_json
        end
      end

      def set_pagination_aria_labels
        @aria_labels = {
          previous: {
            enabled: I18n.t('components.activity.dialog.pagination.previous_aria_label'),
            disabled: I18n.t('components.dialog.pagination.at_first_aria_label')
          },
          next: {
            enabled: I18n.t('components.activity.dialog.pagination.next_aria_label'),
            disabled: I18n.t('components.dialog.pagination.at_last_aria_label')
          }
        }.to_json
      end
    end
  end
end
