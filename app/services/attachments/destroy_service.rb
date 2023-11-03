# frozen_string_literal: true

module Attachments
  # Service used to Delete Projects
  class DestroyService < BaseService
    def initialize(attachable, attachment, user = nil)
      super(user)
      @attachable = attachable
      @attachment = attachment
    end

    def execute
      authorize! @attachable.project, to: :destroy?

      destroyed_attachments = []
      if @attachable.instance_of?(Sample) && @attachment.associated_attachment
        associated_attachment = @attachment.associated_attachment
        associated_attachment.destroy
        destroyed_attachments.append(associated_attachment)
      end

      @attachment.destroy
      destroyed_attachments.append(@attachment)
      destroyed_attachments
    end
  end
end
