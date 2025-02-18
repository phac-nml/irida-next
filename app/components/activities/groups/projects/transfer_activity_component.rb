# frozen_string_literal: true

module Activities
  module Groups
    module Projects
      # Component for rendering group project transferred in/out activity
      class TransferActivityComponent < Component
        def initialize(activity: nil)
          @activity = activity
        end

        def project_exists
          return false if @activity[:project].nil?

          !@activity[:project].deleted? && (@activity[:project].parent == @activity[:group])
        end
      end
    end
  end
end
