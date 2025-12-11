# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering project sample clone activity
    class SampleCloneActivityComponent < Activities::BaseActivityComponent
      def namespace_puid(namespace)
        return namespace.puid unless namespace.nil?
        return @activity[:target_project_puid] if @activity[:target_project_puid]

        @activity[:source_project_puid]
      end

      def project_exists?(namespace)
        return false if namespace.nil?

        !namespace.deleted? && !namespace.project.deleted?
      end

      def activity_namespace
        @activity[:source_project].presence || @activity[:target_project]
      end

      def activity_message # rubocop:disable Metrics/MethodLength
        namespace = activity_namespace
        href = if project_exists?(namespace)
                 link_to(
                   namespace_puid(namespace),
                   namespace_project_samples_path(namespace.parent, namespace.project),
                   class: active_link_classes,
                   title:
                     t(
                       'components.activity.samples.clone.link_descriptive_text',
                       project_puid: namespace_puid(namespace)
                     )
                 )
               else
                 highlighted_text(namespace_puid(namespace))
               end

        t(@activity[:key], user: @activity[:user], href: href,
                           cloned_samples_count: highlighted_text(@activity[:cloned_samples_count]))
      end
    end
  end
end
