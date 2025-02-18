module Activities
  module Groups
    # Component for rendering a metadata template activity for groups
    class RemovedSubgroupActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def removed_group
        !@activity[:removed_group_puid].nil?
      end
    end
  end
end
