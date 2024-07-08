# frozen_string_literal: true

module Projects
  module Samples
    module Attachments
      # Controller actions for Project Samples Attachments Concatenation
      class DeletionsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @sample, to: :destroy_attachment?
          render turbo_stream: turbo_stream.update('sample_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end

        def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          authorize! @sample, to: :destroy_attachment?

          attachments_to_delete = get_attachments(deletion_params['attachment_ids'])
          attachments_to_delete_count = attachments_to_delete.count

          attachments_to_delete.each do |attachment|
            attachments_to_delete -= ::Attachments::DestroyService.new(@sample, attachment, current_user).execute
          end

          # No selected attachments were destroyed
          if attachments_to_delete.count.positive? && attachments_to_delete.count == attachments_to_delete_count
            render status: :unprocessable_entity,
                   locals: { message: nil, not_deleted_attachments: attachments_to_delete }
          # Only some selected attachments were destroyed
          elsif attachments_to_delete.count.positive?
            render status: :multi_status,
                   locals: { type: :success, message: t('.partial_success'),
                             not_deleted_attachments: attachments_to_delete }
          # All selected attachments were destroyed
          else
            render status: :ok, locals: { type: :success, message: t('.success'), not_deleted_attachments: nil }
          end
        end

        private

        def deletion_params
          params.require(:deletion).permit(attachment_ids: {})
        end

        def get_attachments(attachment_ids)
          attachments_to_delete = []
          attachment_ids.each_value do |attachment_id|
            if attachment_id.is_a?(Array)
              attachment_id.each do |paired_attachment_id|
                attachments_to_delete << Attachment.find(paired_attachment_id)
              end
            else
              attachment = Attachment.find(attachment_id)
              attachments_to_delete << attachment
            end
          end
          attachments_to_delete
        end
      end
    end
  end
end
