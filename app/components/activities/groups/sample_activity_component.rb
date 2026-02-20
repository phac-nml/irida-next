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

      def bulk_metadata_update_action?
        @activity[:action] == 'group_bulk_metadata_update'
      end

      def activity_message
        case @activity[:action]

        when 'group_import_samples'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:imported_samples_count]))
        when 'group_samples_destroy'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:samples_deleted_count]))
        when 'group_bulk_metadata_update'
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
        when 'group_bulk_metadata_update'
          t('components.activity.samples.bulk_metadata_update.more_details.button_descriptive_text')
        else
          ''
        end
      end

      def dialog_type
        @activity[:action]
      end

      def show_more_details_button?
        import_samples_action? || sample_destroy_action? || bulk_metadata_update_action?
      end
    end
  end
end
