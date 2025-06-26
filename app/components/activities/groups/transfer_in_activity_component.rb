# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering a subgroup transferred into a group activity
    class TransferInActivityComponent < Activities::BaseActivityComponent
      def existing_group_namespace
        !@activity[:old_namespace].nil?
      end

      def transferred_group_exists
        return false if @activity[:transferred_group].nil?

        !@activity[:transferred_group].deleted?
      end

      def activity_message # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        href = if transferred_group_exists
                 link_to(
                   @activity[:transferred_group_puid],
                   group_path(@activity[:transferred_group]),
                   class: active_link_classes,
                   title:
                     t(
                       'components.activity.subgroups.link_descriptive_text',
                       subgroup_puid: @activity[:transferred_group_puid]
                     )
                 )
               else
                 highlighted_text(@activity[:transferred_group_puid])
               end

        if existing_group_namespace
          t(
            @activity[:key],
            user: @activity[:user],
            old_namespace: highlighted_text(@activity[:old_namespace]),
            new_namespace: highlighted_text(@activity[:new_namespace]),
            href: href
          )
        else
          t(
            @activity[:key],
            user: @activity[:user],
            new_namespace: highlighted_text(@activity[:new_namespace]),
            href: href
          )
        end
      end
    end
  end
end
