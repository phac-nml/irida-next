# frozen_string_literal: true

module Attachments
  module Dialogs
    # Component for rendering a new upload dialog component for attachments
    class DeleteAttachmentComponent < Component
      def initialize(
        attachment,
        namespace,
        open
      )
        @attachment = attachment
        @namespace = namespace
        @open = open
      end

      def destroy_path
        if @namespace.type == 'Group'
          group_attachment_path(id: @attachment.id)
        else
          namespace_project_attachment_path(id: @attachment.id)
        end
      end
    end
  end
end
