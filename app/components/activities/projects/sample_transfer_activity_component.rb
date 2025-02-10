# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering an sample transfer activity of type Namespace for Projects
    class SampleTransferActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end

      def project_exists(namespace)
        !namespace.deleted? && !namespace.project.deleted?
      end
    end
  end
end
