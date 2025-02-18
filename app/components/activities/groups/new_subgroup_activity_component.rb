module Activities
  module Groups
    # Component for rendering a metadata template activity for groups
    class NewSubgroupActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def group_exists
        return false if @activity[:created_group].nil?

        !@activity[:created_group].deleted?
      end
    end
  end
end
