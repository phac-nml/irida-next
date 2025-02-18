module Activities
  module Groups
    # Component for rendering a subgroup transferred out of a group activity
    class TransferOutActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end
    end
  end
end
