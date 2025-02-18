module Activities
  module Groups
    # Component for rendering a metadata template activity for groups
    class MetadataTemplateActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def destroy_template
        @activity[:action] == 'metadata_template_destroy'
      end

      def template_exists
        return false if @activity[:template].nil?

        !@activity[:template].deleted?
      end
    end
  end
end
