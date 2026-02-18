# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering an group sample activity
    class SampleActivityComponent < Activities::BaseActivityComponent
      def import_samples_action?
        @activity[:action] == 'group_import_samples'
      end

      def sample_destroy_action?
        @activity[:action] == 'group_samples_destroy'
      end

      def import_metadata_action?
        @activity[:action] == 'group_import_metadata'
      end

      def activity_message
        case @activity[:action]

        when 'group_import_samples'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:imported_samples_count]))
        when 'group_samples_destroy'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:samples_deleted_count]))
        when 'group_import_metadata'
          t(@activity[:key], user: @activity[:user],
                             href: highlighted_text(@activity[:imported_metadata_samples_count]))
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
        when 'group_import_metadata'
          t('components.activity.samples.import_metadata.more_details.button_descriptive_text')
        else
          ''
        end
      end

      def dialog_type
        @activity[:action]
      end

      def show_more_details_button?
        import_samples_action? || sample_destroy_action? || import_metadata_action?
      end
    end
  end
end
