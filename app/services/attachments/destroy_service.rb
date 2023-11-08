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

    def execute # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      authorize! @attachable.project, to: :destroy?

      if @attachment.attachable_id != @attachable.id || !@attachable.is_a?(@attachment.attachable_type.constantize)
        raise AttachmentsDestroyError, I18n.t('services.attachments.destroy.does_not_belong_to_attachable')
      end

      destroyed_attachments = []
      if @attachable.instance_of?(Sample) && @attachment.associated_attachment
        if @attachment.associated_attachment.attachable_id != @attachable.id
          raise AttachmentsDestroyError,
                I18n.t('services.attachments.destroy.associated_att_does_not_belong_to_attachable')
        end

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
