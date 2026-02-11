# frozen_string_literal: true

module WorkflowExecutions
  # Controller actions for FileSelector
  class FileSelectorController < ApplicationController # rubocop:disable Metrics/ClassLength
    before_action :namespace, only: %i[new create]
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
      expected_params = [
        :attachable_id,
        :attachable_type,
        :property,
        :selected_id,
        :pattern,
        :namespace_id,
        { required_properties: [] }
      ]
      expected_params.push(:index) unless Flipper.enabled?(:deferred_samplesheet)
      params.expect(file_selector: expected_params)
    end

    def namespace
      @namespace = Namespace.find(file_selector_params[:namespace_id])
    end

    def listing_attachments
      if Flipper.enabled?(:deferred_samplesheet)
        listing_attachments_with_feature_flag
      else
        listing_attachments_without_feature_flag
      end
    end

    def listing_attachments_with_feature_flag
      pe_only = file_selector_params.key?('required_properties') &&
                file_selector_params['required_properties'].include?('fastq_1') &&
                file_selector_params['required_properties'].include?('fastq_2')
      @listing_attachments = case file_selector_params['property']
                             when 'fastq_1', 'fastq_2'
                               @attachable.file_selector_fastq_files(file_selector_params['property'], pe_only)
                             else
                               @attachable.file_selector_other_files(file_selector_params['pattern'])
                             end
    end

    def listing_attachments_without_feature_flag
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
      authorize! @namespace, to: :update_samplesheet_data?

      attachable_id = file_selector_params[:attachable_id]
      case file_selector_params[:attachable_type]
      when Sample.sti_name
        @attachable = Sample.find(attachable_id)
      when Namespaces::ProjectNamespace.sti_name
        @attachable = Namespace.find(attachable_id)
      end
    end

    def attachments # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @attachments_params = { files: [] }
      if Flipper.enabled?(:deferred_samplesheet)
        @attachments_params[:attachable_id] = file_selector_params[:attachable_id]
      else
        @attachments_params[:index] = file_selector_params[:index]
      end

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
