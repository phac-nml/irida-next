module Activities
  module Groups
    # Component for rendering a subgroup transferred out of a group activity
    class TransferInActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def existing_group_namespace
        !@activity[:old_namespace].nil?
      end

      def transferred_group_exists
        return false if @activity[:transferred_group].nil?

        !@activity[:transferred_group].deleted? && (@activity[:transferred_group].parent_id == @activity[:group].id)
      end
    end
  end
end
