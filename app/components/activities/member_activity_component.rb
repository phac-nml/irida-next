# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Member
  class MemberActivityComponent < BaseActivityComponent
    def members_page
      if @activity[:member].namespace.group_namespace?
        group_members_path(@activity[:member].namespace)
      elsif @activity[:member].namespace.project_namespace?
        namespace_project_members_path(
          @activity[:member].namespace.project.parent,
          @activity[:member].namespace.project
        )
      end
    end

    def member_exists?
      return false if @activity[:member].nil?

      !@activity[:member].deleted?
    end

    def activity_message # rubocop:disable Metrics/MethodLength
      href = if member_exists?
               link_to(
                 @activity[:member_email],
                 members_page,
                 class: active_link_classes,
                 title:
                   t(
                     'components.activity.members.link_descriptive_text',
                     namespace_type: @activity[:member].namespace.type.downcase
                   )
               )
             else
               highlighted_text(@activity[:member_email])
             end

      t(
        @activity[:key],
        user: @activity[:user],
        href: href,
        namespace_type: @activity[:namespace_type],
        name: @activity[:name],
        member: @activity[:member_email]
      )
    end
  end
end
