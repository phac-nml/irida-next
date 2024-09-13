# frozen_string_literal: true

module Activities
  # Component for rendering an activity list item
  class ListItemComponent < Component
    attr_accessor :activity

    def initialize(activity: nil, **system_arguments)
      @activity = activity
      @system_arguments = system_arguments
      @activity_requires_dialog = false
      dialog_variables
    end

    def dialog_variables # rubocop:disable Metrics/MethodLength
      case activity[:action]
      when 'sample_destroy_multiple'
        @dialog_title = 'Samples deleted'
        @dialog_launch_button_text = 'View deleted samples'
        @dialog_description = 'These are the samples that were deleted'
        @sample_puids = activity[:samples_deleted_puids]
        @activity_requires_dialog = true
      when 'sample_transfer'
        @dialog_title = 'Samples transferred'
        @dialog_launch_button_text = 'View transferred samples'
        @dialog_description = 'These are the samples that were transferred'
        @sample_puids = activity[:transferred_samples_puids]
        @activity_requires_dialog = true
      when 'sample_clone'
        @dialog_title = 'Samples cloned'
        @dialog_launch_button_text = 'View cloned samples'
        @dialog_description = 'These are the samples that were cloned'
        @sample_puids = activity[:cloned_samples_puids]
        @activity_requires_dialog = true
      end
    end
  end
end
