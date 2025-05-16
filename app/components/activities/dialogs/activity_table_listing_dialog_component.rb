# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering extended details table
    class ActivityTableListingDialogComponent < Component
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

      # @title, @description, @data, and @column_headers are all required attributes
      def set_additional_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        case @activity_type
        when 'sample_clone'
          @title = I18n.t(:'components.activity.dialog.sample_clone.title')

          project_type = @activity.parameters[:source_project].present? ? 'source' : 'target'

          @description = if project_type == 'source'
                           I18n.t(
                             :'components.activity.dialog.sample_clone.source_project_description',
                             user: @activity_owner,
                             count: @activity.parameters[:cloned_samples_count],
                             source_project_puid: @activity.parameters[:source_project_puid]
                           )
                         else
                           I18n.t(
                             :'components.activity.dialog.sample_clone.target_project_description',
                             user: @activity_owner,
                             count: @activity.parameters[:cloned_samples_count],
                             target_project_puid: @activity.parameters[:target_project_puid]
                           )
                         end

          @data = @extended_details.details['cloned_samples_data'].to_json
          @column_headers = [
            I18n.t(:'components.activity.dialog.sample_clone.copied_from'),
            I18n.t(:'components.activity.dialog.sample_clone.copied_to')
          ]

        when 'group_sample_transfer'
          @title = I18n.t(:'components.activity.dialog.group_sample_transfer.title')

          @description = I18n.t(
            :'components.activity.dialog.group_sample_transfer.description',
            user: @activity_owner,
            count: @activity.parameters[:transferred_samples_count]
          )

          @data = @extended_details.details['transferred_samples_data'].to_json
          @column_headers = [
            I18n.t(:'components.activity.dialog.group_sample_transfer.sample_name'),
            I18n.t(:'components.activity.dialog.group_sample_transfer.transferred_from'),
            I18n.t(:'components.activity.dialog.group_sample_transfer.transferred_to')
          ]

        when 'workflow_execution_destroy'
          @title = I18n.t(:'components.activity.dialog.workflow_execution_destroy.title')
          @description = I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                                user: @activity_owner,
                                count: @activity.parameters[:workflow_executions_deleted_count])
          @data = @extended_details.details['deleted_workflow_executions_data'].to_json

          @column_headers = [
            I18n.t(:'components.activity.dialog.workflow_execution_destroy.name'),
            I18n.t(:'components.activity.dialog.workflow_execution_destroy.id')
          ]

        when 'group_import_samples'
          @title = I18n.t(:'components.activity.dialog.import_samples.title')
          @description = I18n.t('components.activity.dialog.import_samples.description.group',
                                user: @activity_owner,
                                count: @activity.parameters[:imported_samples_count])
          @data = @extended_details.details['imported_samples_data'].to_json
          @column_headers = [
            I18n.t(:'components.activity.dialog.import_samples.sample'),
            I18n.t(:'components.activity.dialog.import_samples.project')
          ]
        end
      end

      def set_pagination_aria_labels
        @aria_labels = {
          previous: {
            enabled: I18n.t('components.activity.dialog.pagination.previous_aria_label'),
            disabled: I18n.t('components.activity.dialog.pagination.at_first_aria_label')
          },
          next: {
            enabled: I18n.t('components.activity.dialog.pagination.next_aria_label'),
            disabled: I18n.t('components.activity.dialog.pagination.at_last_aria_label')
          }
        }.to_json
      end
    end
  end
end
