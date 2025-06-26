# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an project sample activity
    class SampleActivityComponent < Activities::BaseActivityComponent
      def sample_destroy_multiple_action
        @activity[:action] == 'sample_destroy_multiple'
      end

      def sample_exists(sample)
        return false if sample.nil?
        return false if sample&.project&.namespace != @activity[:current_project]

        !sample.deleted?
      end

      def samples_tab
        @activity[:action] == 'metadata_update' ? 'metadata' : ''
      end

      def import_samples_action
        @activity[:action] == 'project_import_samples'
      end

      def activity_message # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        case @activity[:action]

        when 'project_import_samples'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:imported_samples_count]))
        when 'sample_destroy_multiple'
          t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:samples_deleted_count]))
        else
          if sample_exists(@activity[:sample])
            url = namespace_project_sample_path(
              @activity[:current_project].parent,
              @activity[:current_project].project,
              id: @activity[:sample_id]
            )
            sample_url = link_to(
              @activity[:sample_puid],
              path_with_params(url, { tab: samples_tab }),
              class: active_link_classes,
              title:
                t(
                  'components.activity.samples.link_descriptive_text',
                  sample_puid: @activity[:sample_puid]
                )
            )

            t(@activity[:key], user: @activity[:user], href: sample_url)
          else
            t(@activity[:key], user: @activity[:user], href: highlighted_text(@activity[:sample_puid]))
          end
        end
      end

      def descriptive_text
        case @activity[:action]

        when 'sample_destroy_multiple'
          t('components.activity.samples.destroy.more_details.button_descriptive_text')
        when 'project_import_samples'
          t('components.activity.samples.import.more_details.button_descriptive_text')
        else
          ''
        end
      end

      def dialog_type
        case @activity[:action]
        when 'sample_destroy_multiple'
          'samples_destroy'
        when 'project_import_samples'
          'project_import_samples'
        end
      end

      def show_more_details_button?
        import_samples_action || sample_destroy_multiple_action
      end
    end
  end
end
