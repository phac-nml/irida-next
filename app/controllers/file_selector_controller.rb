# frozen_string_literal: true

# Controller actions for Projects
class FileSelectorController < ApplicationController
  before_action :attachable, only: %i[new create]
  before_action :attachments, only: %i[create]
  before_action :listing_attachments, only: %i[new create]

  def new
    render turbo_stream: turbo_stream.update('file_selector_dialog',
                                               partial: 'file_selector/file_selector_dialog',
                                               locals: {attachable: @attachable, file_selector_params:, open: true}), status: :ok
  end

  def create
    respond_to do |format|
      format.turbo_stream do
        render status: :ok, locals: {file_selector_params:}
      end
    end
  end

  private

  def file_selector_params
    params.require(:file_selector).permit(:attachable, :index, :name, :selected_id, :required, file_filter_params: [:pattern, :direction, :pe_only])
  end

  def listing_attachments
    filter_params = file_selector_params[:file_filter_params]
    pattern = filter_params[:pattern] == "" ? nil : filter_params[:pattern]
    direction = filter_params[:direction].to_sym
    pe_only = filter_params[:pe_only] == "true"
    files = @attachable.fastq_files(pattern, direction, pe_only)
    @listing_attachments = Attachment.where(id: files.map{|i| i[:id]})
  end

  def attachable
    @attachable = Sample.find(file_selector_params[:attachable])
  end

  def attachments
    @attachment_params = {}
    return if params[:attachment_id] == 'no_attachment'
    attachment = Attachment.find(params[:attachment_id])
    @attachment_params = {filename: attachment.filename.to_s, global_id: attachment.to_global_id, id: attachment.id}
    return unless attachment.associated_attachment && (file_selector_params[:name] == 'fastq_1' || file_selector_params[:name] == 'fastq_2')

    @associated_attachment_params = {}
    associated_attachment = attachment.associated_attachment

    @associated_attachment_params[:file] = {filename: associated_attachment.filename.to_s, global_id: associated_attachment.to_global_id, id: associated_attachment.id}
    @associated_attachment_params[:name] = file_selector_params["name"] == "fastq_1" ? "fastq_2" : "fastq_1"
    @associated_attachment_params[:file_filter_params] = {
      pattern: file_selector_params[:file_filter_params][:pattern],
    direction:  file_selector_params[:file_filter_params][:direction] == "pe_forward" ? "pe_reverse" : "pe_forward",
    pe_only: file_selector_params[:file_filter_params][:pe_only]
    }

  end
end
