# frozen_string_literal: true

module Activities
  module Projects
    # Component for rendering a metadata template activity for projects
    class MetadataTemplateActivityComponent < BaseActivityComponent
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
