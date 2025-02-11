# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an activity of type Namespace for Projects
    class SampleCloneActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end

      def project_exists(namespace)
        return false if namespace.nil?

        !namespace.deleted? && !namespace.project.deleted?
      end
    end
  end
end
