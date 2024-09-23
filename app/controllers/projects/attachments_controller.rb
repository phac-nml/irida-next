# frozen_string_literal: true

module Projects
  # Controller actions for Project Attachments
  class AttachmentsController < Projects::ApplicationController
    include Metadata
    include AttachmentActions

    private

    def set_model
      @namespace = @project.namespace
    end

    def set_authorization_object
      @authorize_object = @project
    end

    def current_page
      @current_page = t(:'projects.sidebar.files')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: t(:'projects.sidebar.files'),
          path: namespace_project_attachments_path(@project.parent, @project)
        }]
    end
  end
end
