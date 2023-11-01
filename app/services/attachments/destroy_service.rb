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
      return unless @attachable.instance_of?(Sample)

      attachments = []
      return unless @attachment.attachable_type == 'Sample' && @attachment.attachable_id == @attachable.id

      if @attachment.associated_attachment
        associated_attachment = @attachment.associated_attachment
        associated_attachment.destroy
        attachments.append(associated_attachment)
      end

      @attachment.destroy
      attachments.append(@attachment)
      attachments
    end
  end
end
