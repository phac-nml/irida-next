# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering extended details list items
    class SampleActivityListDialogComponent < Component
      attr_accessor :activity, :activity_owner, :activity_type

      def initialize(activity: nil, extended_details: nil, activity_owner: nil)
        @activity = activity
        @activity[:parameters] = @activity.parameters.transform_keys(&:to_sym)
        @extended_details = extended_details
        @activity_owner = activity_owner
        @activity_type = @activity.parameters[:action]
        set_params
      end

      def set_params # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        if @activity_type == 'sample_transfer'
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

          @table_data = @extended_details.details['transferred_samples_data'].to_json

        elsif @activity_type == 'sample_destroy_multiple'
          @title = I18n.t(:'components.activity.dialog.sample_destroy.title')
          @description = I18n.t(:'components.activity.dialog.sample_destroy.description',
                                user: @activity_owner,
                                count: @activity.parameters[:samples_deleted_count])
          @table_data = @extended_details.details['deleted_samples_data'].to_json
        end
      end
    end
  end
end
