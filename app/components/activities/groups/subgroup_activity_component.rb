# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering a subgroup activity for groups
    class SubgroupActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def destroy_subgroup
        !@activity[:removed_group_puid].nil?
      end

      def subgroup_exists
        return false if @activity[:created_group].nil?
        return false if @activity[:created_group].parent != @activity[:group]

        !@activity[:created_group].deleted?
      end
    end
  end
end
