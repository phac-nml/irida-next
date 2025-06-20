# frozen_string_literal: true

module Activities
  module Groups
    # Component for rendering a subgroup transferred into a group activity
    class TransferInActivityComponent < Component
      def initialize(activity: nil)
        @activity = activity
      end

      def existing_group_namespace
        !@activity[:old_namespace].nil?
      end

      def transferred_group_exists
        return false if @activity[:transferred_group].nil?

        !@activity[:transferred_group].deleted?
      end
    end
  end
end
