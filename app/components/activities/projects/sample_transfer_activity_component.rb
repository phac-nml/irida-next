# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering project sample transfer activity
    class SampleTransferActivityComponent < BaseActivityComponent
      def project_exists(namespace)
        return false if namespace.nil?

        !namespace.deleted? && !namespace.project.deleted?
      end
    end
  end
end
