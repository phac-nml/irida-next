# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering a metadata template activity for projects
    class MetadataTemplateActivityComponent < Component
      include PathHelper

      def initialize(activity: nil)
        @activity = activity
      end

      def destroy_template
        @activity[:action] == 'metadata_template_destroy'
      end

      def template_exists
        !@activity[:template].deleted?
      end
    end
  end
end
