# frozen_string_literal: true

module Activities
  # Component for rendering an activity of type Namespace for Projects
  class ProjectActivityComponent < Component
    def initialize(activity: nil, **system_arguments)
      @activity = activity

      @system_arguments = system_arguments
    end

    def sample_link
      @activity[:action] == 'sample_create' || @activity[:action] == 'sample_update' ||
        @activity[:action] == 'attachment_create' || @activity[:action] == 'attachment_destroy'
    end

    def samples_link
      @activity[:action] == 'sample_clone' || @activity[:action] == 'sample_transfer'
    end
  end
end
