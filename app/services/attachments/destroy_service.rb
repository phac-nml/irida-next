# frozen_string_literal: true

module Attachments
  # Service used to Delete Projects
  class DestroyService < BaseService
    attr_accessor :destroyed_attachments

    AttachmentsDestroyError = Class.new(StandardError)
    def initialize(attachable, attachment, user = nil)
      super(user)
      @attachable = attachable
      @attachment = attachment
      @destroyed_attachments = []
    end

    def execute # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      attachable_authorization

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

      destroyed_attachments.append(@attachment)
      create_activities if attachment_destroyed

      destroyed_attachments
    rescue Attachments::DestroyService::AttachmentsDestroyError => e
      @attachment.errors.add(:base, e.message)
      destroyed_attachments
    end

    private

    def attachable_authorization
      if @attachable.instance_of?(Namespaces::ProjectNamespace)
        authorize! @attachable.project, to: :destroy_attachment?
      else
        authorize! @attachable, to: :destroy_attachment?
      end
    end

    def create_activities
      return if @attachment.metadata.key?('direction') && @attachment.metadata['direction'] == 'reverse'

      group_activity if @attachable.instance_of?(Group)
      project_activity if @attachable.instance_of?(Namespaces::ProjectNamespace)
      sample_activity if @attachable.instance_of?(Sample)
    end

    def group_activity
      @attachable.create_activity key: 'group.attachment.destroy',
                                  owner: current_user,
                                  trackable_id: @attachable.id,
                                  parameters: {
                                    deleted_attachments_ids: deleted_attachment_ids,
                                    deleted_attachments_puids: deleted_attachment_puids,
                                    action: 'group_attachment_destroy'
                                  }
    end

    def project_activity
      @attachable.create_activity key: 'namespaces_project_namespace.attachment.destroy',
                                  owner: current_user,
                                  trackable_id: @attachable.id,
                                  parameters: {
                                    deleted_attachments_ids: deleted_attachment_ids,
                                    deleted_attachments_puids: deleted_attachment_puids,
                                    action: 'project_attachment_destroy'
                                  }
    end

    def sample_activity
      @attachable.project.namespace.create_activity key: 'namespaces_project_namespace.samples.attachment.destroy',
                                                    owner: current_user,
                                                    trackable_id: @attachable.id,
                                                    parameters: {
                                                      deleted_attachments_ids: deleted_attachment_ids,
                                                      deleted_attachments_puids: deleted_attachment_puids,
                                                      sample_puid: @attachable.puid,
                                                      sample_id: @attachable.id,
                                                      action: 'attachment_destroy'
                                                    }
    end

    def deleted_attachment_puids
      @destroyed_attachments.pluck(:puid)
    end

    def deleted_attachment_ids
      @destroyed_attachments.pluck(:id)
    end
  end
end
