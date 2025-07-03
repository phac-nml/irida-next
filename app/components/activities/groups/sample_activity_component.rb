# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering an group sample activity
    class SampleActivityComponent < Activities::BaseActivityComponent
      def import_samples_action
        @activity[:action] == 'group_import_samples'
      end

      def sample_destroy_action
        @activity[:action] == 'group_samples_destroy'
      end

      def activity_message
        case @activity[:action]

        when 'group_import_samples'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:imported_samples_count]))
        when 'group_samples_destroy'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:samples_deleted_count]))
        else
          ''
        end
      end

      def descriptive_text
        case @activity[:action]

        when 'group_import_samples'
          t('components.activity.samples.import.more_details.button_descriptive_text')
        when 'group_samples_destroy'
          t('components.activity.samples.destroy.more_details.button_descriptive_text')
        else
          ''
        end
      end

      def dialog_type
        case @activity[:action]
        when 'group_import_samples'
          'group_import_samples'
        when 'group_samples_destroy'
          'group_samples_destroy'
        end
      end

      def show_more_details_button?
        import_samples_action || sample_destroy_action
      end
    end
  end
end
