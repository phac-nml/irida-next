# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering project sample transfer activity
    class SampleTransferActivityComponent < BaseActivityComponent
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
