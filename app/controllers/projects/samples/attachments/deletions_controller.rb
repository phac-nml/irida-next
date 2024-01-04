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

          attachments_to_del = get_attachments(deletion_params['attachment_ids'])
          attachments_to_del_count = attachments_to_del.count

          attachments_to_del.each do |attachment|
            attachments_to_del -= ::Attachments::DestroyService.new(@sample, attachment, current_user).execute
          end
          respond_to do |format|
            status = get_response_status(attachments_to_del, attachments_to_del_count)
            format.turbo_stream do
              if status == :unprocessable_entity
                render status:, locals: { message: nil, attachments: attachments_to_del }
              elsif status == :multi_status
                render status:,
                       locals: { type: :success, message: t('.partial_success'),
                                 attachments: attachments_to_del }
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
          attachments_to_del = []
          attachment_ids.each do |_k, attachment_id|
            if attachment_id.is_a?(Array)
              attachment_one = Attachment.find(attachment_id[0])
              attachment_two = Attachment.find(attachment_id[1])
              attachments_to_del << attachment_one
              attachments_to_del << attachment_two
            else
              attachment = Attachment.find(attachment_id)
              attachments_to_del << attachment
            end
          end
          attachments_to_del
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
