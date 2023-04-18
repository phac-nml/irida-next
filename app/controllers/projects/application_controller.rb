# frozen_string_literal: true

module Projects
  # Base Controller for Projects
  class ApplicationController < ApplicationController
    layout 'projects'

    def authorize_view_members!
      authorize! @project, to: :allowed_to_view_members?
    end

    def authorize_owner_namespace!
      authorize! @project, to: :new?
    end

    def authorize_view_samples!
      authorize! @project, to: :allowed_to_view_samples?
    end

    def authorize_sample_modification!
      authorize! @project, to: :allowed_to_modify_samples?
    end

    def authorize_create_project!
      authorize! @project
    end

    def authorize_viewable_project_member!
      authorize! @project
    end
  end
end
