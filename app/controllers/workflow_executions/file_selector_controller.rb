# frozen_string_literal: true

module WorkflowExecutions
  # Controller actions for FileSelector
  class FileSelectorController < ApplicationController
    before_action :attachable, only: %i[new create]
    before_action :attachments, only: %i[create]
    before_action :listing_attachments, only: %i[new create]

    def new
      render turbo_stream: turbo_stream.update('file_selector_dialog',
                                               partial: 'file_selector_dialog',
                                               locals: { file_selector_params:, open: true }), status: :ok
    end

    def create
      respond_to do |format|
        format.turbo_stream do
          render status: :ok, locals: { file_selector_params: }
        end
      end
    end

    private

    def file_selector_params
      params.require(:file_selector).permit(
        :attachable_id,
        :attachable_type,
        :index,
        :property,
        :selected_id,
        :pattern,
        required_properties: []
      )
    end

    def listing_attachments
      @listing_attachments = case file_selector_params['property']
                             when 'fastq_1', 'fastq_2'
                               @attachable.samplesheet_fastq_files(
                                 file_selector_params['property'], file_selector_params['pattern']
                               )
                             else
                               if file_selector_params['pattern']
                                 @attachable.filter_files_by_pattern(
                                   @attachable.sorted_files[:singles] || [],
                                   file_selector_params['pattern']
                                 )
                               else
                                 @attachable.sorted_files[:singles] || []
                               end
                             end
    end

    def attachable
      attachable_id = file_selector_params[:attachable_id]
      case file_selector_params[:attachable_type]
      when Sample.sti_name
        @attachable = Sample.find(attachable_id)
      when Namespaces::ProjectNamespace.sti_name
        @attachable = Namespace.find(attachable_id)
      end
    end

    def attachments
      @attachments_params = {
        index: file_selector_params[:index],
        files: []
      }
      property = file_selector_params['property']
      if params[:attachment_id] == 'no_attachment'
        add_attachment_to_params(nil, property)
      else
        attachment = Attachment.find(params[:attachment_id])
        add_attachment_to_params(attachment, property)

        return unless %w[fastq_1 fastq_2].include?(property)

        associated_property = property == 'fastq_1' ? 'fastq_2' : 'fastq_1'
        add_attachment_to_params(attachment.associated_attachment, associated_property)
      end
    end

    def add_attachment_to_params(attachment, property)
      @attachments_params[:files] << if attachment
                                       { filename: attachment.file.filename.to_s,
                                         global_id: attachment.to_global_id,
                                         id: attachment.id,
                                         property: }
                                     else
                                       { filename: '',
                                         global_id: '',
                                         id: '',
                                         property: }
                                     end
    end
  end
end
