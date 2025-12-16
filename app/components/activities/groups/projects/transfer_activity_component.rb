# frozen_string_literal: true

module Activities
  module Groups
    module Projects
      # Component for rendering group project transferred in/out activity
      class TransferActivityComponent < Activities::BaseActivityComponent
        def project_exists?
          return false if @activity[:project].nil?

          !@activity[:project].deleted?
        end

        def activity_message # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          href = if project_exists?
                   link_to(
                     @activity[:project_puid],
                     namespace_project_path(
                       @activity[:project].parent,
                       @activity[:project].project
                     ),
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

          t(@activity[:key], user: @activity[:user], href: href,
                             old_namespace: highlighted_text(@activity[:old_namespace]),
                             new_namespace: highlighted_text(@activity[:new_namespace]))
        end
      end
    end
  end
end
