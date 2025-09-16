# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class AttachmentsController < Projects::Samples::ApplicationController
      include SampleAttachment
      before_action :attachment, only: %i[destroy]
      before_action :new_destroy_params, only: %i[new_destroy]
      before_action :view_authorizations, only: %i[destroy create select]

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

        # Refresh the current page

        # redirect_to namespace_project_sample_path(id: @sample.id, tab: 'files')
        respond_to do |format|
          format.turbo_stream do
            render status:, locals: { attachment: Attachment.new(attachable: @sample),
                                      attachments: @attachments }
          end
        end
      end

      def new_destroy
        authorize! @sample, to: :destroy_attachment?
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'delete_attachment_modal',
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
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
                                          errors: error_message(@attachment)),
                               destroyed_attachments: nil }
            end
          end
        end
      end

      def select # rubocop:disable Metrics/MethodLength
        authorize! @project, to: :update_sample?

        @sample_attachment_ids = []

        respond_to do |format|
          format.turbo_stream do
            if params[:select].present?
              @q = load_attachments.ransack(params[:q])
              @q.result.each do |attachment|
                @sample_attachment_ids << if attachment.associated_attachment
                                            [attachment.id, attachment.associated_attachment.id].to_s
                                          else
                                            attachment.id
                                          end
              end
            end
          end
        end
      end

      private

      def view_authorizations
        @allowed_to = {
          destroy_attachment: allowed_to?(:destroy_attachment?, @sample),
          update_sample: allowed_to?(:update_sample?, @project)
        }
      end

      def attachment_params
        params.expect(attachment: [:attachable_id, :attachable_type, { files: [] }])
      end

      def attachment
        @attachment = @sample.attachments.find_by(id: params[:id]) || not_found
      end

      def new_destroy_params
        @attachment = Attachment.find_by(id: params[:attachment_id])
        @sample = @attachment.attachable
      end

      def destroy_status(attachment, count)
        return count == 2 ? :ok : :multi_status if attachment.associated_attachment

        count == 1 ? :ok : :unprocessable_entity
      end
    end
  end
end
