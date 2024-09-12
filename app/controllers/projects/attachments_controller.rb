# frozen_string_literal: true

module Projects
  # Controller actions for Project Attachments
  class AttachmentsController < Projects::ApplicationController
    def index; end
    def new; end

    def create
      authorize! @project, to: :create_attachment?
    end

    def destroy
      authorize! @project, to: :destroy_attachment?
    end
  end
end
