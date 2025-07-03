# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering a metadata template activity for groups
    class MetadataTemplateActivityComponent < Activities::BaseActivityComponent
      def destroy_template
        @activity[:action] == 'metadata_template_destroy'
      end

      def template_exists
        return false if @activity[:template].nil?

        !@activity[:template].deleted?
      end

      def activity_message
        href = if template_exists
                 link_to(
                   @activity[:template_name],
                   group_metadata_templates_path(@activity[:group]),
                   class: active_link_classes,
                   title:
                     t('components.activity.metadata_templates.group.link_descriptive_text')
                 )
               else
                 highlighted_text(@activity[:template_name])
               end

        t(@activity[:key], user: @activity[:user], href: href)
      end
    end
  end
end
