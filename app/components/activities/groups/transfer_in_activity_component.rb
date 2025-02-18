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
    end
  end
end
