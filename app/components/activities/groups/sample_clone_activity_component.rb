# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering project sample clone activity
    class SampleCloneActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def namespace_puid(namespace)
        return namespace.puid unless namespace.nil?
        return @activity[:target_project_puid] if @activity[:target_project_puid]

        @activity[:source_project_puid]
      end

      def project_exists(namespace)
        return false if namespace.nil?

        !namespace.deleted? && !namespace.project.deleted?
      end
    end
  end
end
