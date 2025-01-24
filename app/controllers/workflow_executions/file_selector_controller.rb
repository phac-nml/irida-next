# frozen_string_literal: true

module WorkflowExecutions
  # Controller actions for FileSelector
  class FileSelectorController < ApplicationController
    before_action :attachable, only: %i[new create]
    before_action :attachments, only: %i[create]
    before_action :listing_attachments, only: %i[new create]

    def new
      puts 'hihihhihi'
      puts file_selector_params
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
        :file_type,
        required_properties: [],
        file_selector_arguments: [
          { patterns: {} }, { workflow_params: %i[name version] }
        ]
      )
    end

    def listing_attachments # rubocop:disable Metrics/AbcSize
      case file_selector_params['file_type']
      when 'fastq'
        @listing_attachments = @attachable.samplesheet_fastq_files(
          file_selector_params['property'], file_selector_params['file_selector_arguments']['workflow_params']
        )
      when 'other'
        @listing_attachments = if file_selector_params['file_selector_arguments']['patterns'][file_selector_params['property']]
                                 @attachable.filter_files_by_pattern(
                                   @attachable.sorted_files[:singles] || [],
                                   file_selector_params['file_selector_arguments']['patterns'][file_selector_params['property']]
                                 )
                               else
                                 sample.sorted_files[:singles] || []
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
      @attachment_params = {}
      return if params[:attachment_id] == 'no_attachment'

      attachment = Attachment.find(params[:attachment_id])
      @attachment_params = { filename: attachment.file.filename.to_s,
                             global_id: attachment.to_global_id,
                             id: attachment.id,
                             byte_size: attachment.byte_size,
                             created_at: attachment.created_at,
                             metadata: attachment.metadata }
      return unless %w[fastq_1 fastq_2].include?(file_selector_params['property'])

      assign_associated_attachment_params(attachment)
    end

    def assign_associated_attachment_params(attachment) # rubocop:disable Metrics/MethodLength
      @associated_attachment_params = {}

      @associated_attachment_params[:property] = file_selector_params[:property] == 'fastq_1' ? 'fastq_2' : 'fastq_1'
      @associated_attachment_params[:file_selector_arguments] = {
        workflow_params: file_selector_params['file_selector_arguments']['workflow_params']
      }

      if attachment.associated_attachment
        associated_attachment = attachment.associated_attachment
        @associated_attachment_params[:file] = {
          filename: associated_attachment.filename.to_s,
          global_id: associated_attachment.to_global_id,
          id: associated_attachment.id,
          byte_size: associated_attachment.byte_size,
          created_at: associated_attachment.created_at,
          metadata: associated_attachment.metadata
        }
      else
        @associated_attachment_params[:file] = {}
      end
    end
  end
end
