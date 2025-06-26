# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering a subgroup activity for groups
    class SubgroupActivityComponent < Activities::BaseActivityComponent
      def destroy_subgroup
        !@activity[:removed_group_puid].nil?
      end

      def subgroup_exists
        return false if @activity[:created_group].nil?

        !@activity[:created_group].deleted?
      end

      def activity_message # rubocop:disable Metrics/MethodLength
        href = if destroy_subgroup
                 highlighted_text(@activity[:removed_group_puid])
               elsif subgroup_exists
                 link_to(
                   @activity[:created_group_puid],
                   group_path(@activity[:created_group]),
                   class: active_link_classes,
                   title:
                     t(
                       'components.activity.subgroups.link_descriptive_text',
                       subgroup_puid: @activity[:created_group_puid]
                     )
                 )
               else
                 highlighted_text(@activity[:created_group_puid])
               end

        t(@activity[:key], user: @activity[:user], href: href)
      end
    end
  end
end
