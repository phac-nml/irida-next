# frozen_string_literal: true

module Activities
  module Dialogs
    # Component for rendering project sample transfer activity dialog
    class WorkflowExecutionActivityListDialogComponent < Component
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

      def set_additional_params
        return unless @activity_type == 'workflow_execution_destroy'

        @title = I18n.t(:'components.activity.dialog.workflow_execution_destroy.title')
        @description = I18n.t(:'components.activity.dialog.workflow_execution_destroy.description',
                              user: @activity_owner,
                              count: @activity.parameters[:workflow_executions].count)
        @data = @extended_details.details['deleted_workflow_executions_data'].to_json
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
