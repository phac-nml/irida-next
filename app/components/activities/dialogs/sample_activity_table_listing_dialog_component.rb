# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering extended details table
    class SampleActivityTableListingDialogComponent < Component
      attr_accessor :activity, :activity_owner

      def initialize(activity: nil, activity_owner: nil)
        @activity = activity
        @activity[:parameters] = @activity.parameters.transform_keys(&:to_sym)
        @extended_details = activity.extended_details
        @activity_owner = activity_owner
        set_additional_params
      end

      # @title, @description, @data, and @column_headers are all required attributes
      def set_additional_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        return unless @activity.parameters[:action] == 'sample_clone'

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
      end
    end
  end
end
