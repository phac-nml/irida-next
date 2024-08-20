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
      authorize! @attachable, to: :destroy_attachment?
      destroyed_attachments = []
      if @attachment.attachable_id != @attachable.id
        raise AttachmentsDestroyError, I18n.t('services.attachments.destroy.does_not_belong_to_attachable')
      end

      if @attachment.associated_attachment
        if @attachment.associated_attachment.attachable_id != @attachable.id
          raise AttachmentsDestroyError,
                I18n.t('services.attachments.destroy.associated_att_does_not_belong_to_attachable')
        end

        associated_attachment = @attachment.associated_attachment
        associated_attachment.destroy
        destroyed_attachments.append(associated_attachment)
      end

      attachment_destroyed = @attachment.destroy

      if attachment_destroyed
        @attachable.project.namespace.create_activity key: 'namespaces_project_namespace.samples.attachment.destroy',
                                                      owner: current_user,
                                                      trackable_id: @attachable.id,
                                                      parameters: {
                                                        sample_name: @attachable.name,
                                                        sample_id: @attachable.id,
                                                        action: 'attachment_destroy'
                                                      }
      end

      if @attachable.instance_of?(Sample)
        @attachable.create_activity key: 'sample.attachment.destroy', owner: current_user, trackable_id: @attachable.id
      end

      destroyed_attachments.append(@attachment)
      destroyed_attachments
    rescue Attachments::DestroyService::AttachmentsDestroyError => e
      @attachment.errors.add(:base, e.message)
      destroyed_attachments
    end
  end
end
