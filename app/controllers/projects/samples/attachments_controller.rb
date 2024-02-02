# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class AttachmentsController < Projects::Samples::ApplicationController
      before_action :attachment, only: %i[destroy download]

      def new
        authorize! @project, to: :update_sample?

        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'new_attachment_modal',
                                                 locals: {
                                                   open: true,
                                                   attachment: Attachment.new(attachable: @sample)
                                                 }), status: :ok
      end

      def create
        authorize! @project, to: :update_sample?

        @attachments = ::Attachments::CreateService.new(current_user, @sample, attachment_params).execute

        status = if !@attachments.count.positive?
                   :unprocessable_entity
                 elsif @attachments.count(&:persisted?) == @attachments.count
                   :ok
                 else
                   :multi_status
                 end

        respond_to do |format|
          format.turbo_stream do
            render status:, locals: { attachment: Attachment.new(attachable: @sample),
                                      attachments: @attachments }
          end
        end
      end

      def destroy # rubocop:disable Metrics/MethodLength
        authorize! @sample, to: :destroy_attachment?

        @destroyed_attachments = ::Attachments::DestroyService.new(@sample, @attachment, current_user).execute
        respond_to do |format|
          if @destroyed_attachments.count.positive?
            status = destroy_status(@attachment, @destroyed_attachments.length)
            format.turbo_stream do
              render status:, locals: { destroyed_attachments: @destroyed_attachments }
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { message: t('.error',
                                          filename: @attachment.file.filename,
                                          errors: @attachment.errors.full_messages.first),
                               destroyed_attachments: nil }
            end
          end
        end
      end

      def download
        authorize! @project, to: :read_sample?

        send_data @attachment.file.download, filename: @attachment.file.filename.to_s
      end

      private

      def attachment_params
        params.require(:attachment).permit(:attachable_id, :attachable_type, files: [])
      end

      def attachment
        @attachment = @sample.attachments.find_by(id: params[:id]) || not_found
      end

      def destroy_status(attachment, count)
        return count == 2 ? :ok : :multi_status if attachment.associated_attachment

        count == 1 ? :ok : :unprocessable_entity
      end
    end
  end
end
