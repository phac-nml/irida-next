# frozen_string_literal: true

module Attachments
  module Dialogs
    # Component for rendering a upload dialog for attachments
    class NewAttachmentComponent < Component
      def initialize(
        attachment,
        namespace,
        open
      )
        @attachment = attachment
        @namespace = namespace
        @open = open
      end

      def upload_path
        if @namespace.type == 'Group'
          group_attachments_path(id: @namespace.id)
        else
          namespace_project_attachments_path(id: @namespace.project.id)
        end
      end
    end
  end
end
