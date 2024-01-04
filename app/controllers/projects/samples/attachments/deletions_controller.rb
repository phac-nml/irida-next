# frozen_string_literal: true

module Projects
  module Samples
    module Attachments
      # Controller actions for Project Samples Attachments Concatenation
      class DeletionsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @project, to: :update_sample?
          render turbo_stream: turbo_stream.update('sample_files_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end

        def destroy # rubocop:disable Metrics/MethodLength
          authorize! @project, to: :update_sample?

          atts_to_delete = get_attachments(deletion_params['attachment_ids'])
          atts_to_delete_count = atts_to_delete.count

          atts_to_delete.each do |attachment|
            atts_to_delete -= ::Attachments::DestroyService.new(@sample, attachment, current_user).execute
          end
          respond_to do |format|
            status = get_response_status(atts_to_delete, atts_to_delete_count)
            format.turbo_stream do
              if status == :unprocessable_entity
                render status:, locals: { message: nil, attachments: atts_to_delete }
              elsif status == :multi_status
                render status:,
                       locals: { type: :success, message: t('.partial_success'),
                                 attachments: atts_to_delete }
              else
                render status: :ok, locals: { type: :success, message: t('.success'), attachments: nil }
              end
            end
          end
        end

        private

        def deletion_params
          params.require(:deletion).permit(attachment_ids: {})
        end

        def get_attachments(attachment_ids)
          atts_to_delete = []
          attachment_ids.each do |_k, attachment_id|
            if attachment_id.is_a?(Array)
              attachment_one = Attachment.find(attachment_id[0])
              attachment_two = Attachment.find(attachment_id[1])
              atts_to_delete << attachment_one
              atts_to_delete << attachment_two
            else
              attachment = Attachment.find(attachment_id)
              atts_to_delete << attachment
            end
          end
          atts_to_delete
        end

        def get_response_status(attachments, attachments_count)
          if attachments.count.positive?
            attachments.count == attachments_count ? :unprocessable_entity : :multi_status
          else
            :ok
          end
        end
      end
    end
  end
end
