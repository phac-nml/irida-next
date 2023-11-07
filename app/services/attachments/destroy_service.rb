# frozen_string_literal: true

module Attachments
  # Service used to Delete Projects
  class DestroyService < BaseService
    AttachmentsDestroyError = Class.new(StandardError)
    def initialize(attachable, attachment, user = nil)
      super(user)
      @attachable = attachable
      @attachment = attachment
    end

    def execute
      authorize! @attachable.project, to: :destroy?
      unless @attachment.attachable_id != @attachable.id || !@attachable.is_a?(@attachment.attachable_type.constantize)

      end
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
