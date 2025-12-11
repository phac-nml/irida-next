# frozen_string_literal: true

module Activities
  module Groups
    module Projects
      # Component for rendering a group projects activity
      class CrudActivityComponent < Activities::BaseActivityComponent
        def project_exists?
          return false if @activity[:project].nil?

          !@activity[:project].deleted?
        end

        def activity_message
          href = if project_exists?
                   link_to(
                     @activity[:project_puid],
                     namespace_project_path(@activity[:group], @activity[:project].project),
                     class: active_link_classes,
                     title:
                       t(
                         'components.activity.groups.projects.link_descriptive_text',
                         project_puid: @activity[:project_puid]
                       )
                   )
                 else
                   highlighted_text(@activity[:project_puid])
                 end

          t(@activity[:key], user: @activity[:user], href: href)
        end
      end
    end
  end
end
