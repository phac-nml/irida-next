# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Attachments
    class AttachmentsController < ApplicationController
      before_action :project
      before_action :sample
      before_action :attachment, only: %i[destroy download]

      def create
        authorize! @project, to: :update_sample?

        @attachment = Attachment.new(attachment_params.merge(attachable: @sample))
        respond_to do |format|
          if @attachment.save
            format.turbo_stream do
              render locals: { attachment: Attachment.new,
                               new_attachment: @attachment }
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity, locals: { attachment: @attachment,
                                                              new_attachment: nil }
            end
          end
        end
      end

      def destroy
        authorize! @project, to: :update_sample?

        return unless @attachment.destroy

        respond_to do |format|
          format.turbo_stream
        end
      end

      def download
        authorize! @project, to: :read_sample?

        send_data @attachment.file.download, filename: @attachment.file.filename.to_s
      end

      private

      def attachment_params
        params.require(:attachment).permit(:file)
      end

      def attachment
        @attachment = @sample.attachments.find_by(id: params[:id]) || not_found
      end

      def sample
        @sample = @project.samples.find_by(id: params[:sample_id]) || not_found
      end

      def project
        path = [params[:namespace_id], params[:project_id]].join('/')
        @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      end
    end
  end
end
