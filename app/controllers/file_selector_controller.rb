# frozen_string_literal: true

# Controller actions for Projects
class FileSelectorController < ApplicationController
  before_action :attachable, :index, :name, only: %i[new create]
  before_action :selected, only: %i[new]
  before_action :attachments, only: %i[create]

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
    params.require(:file_selector).permit(:attachable, :index, :name, :selected_id, :required)
  end

  def attachable
    @attachable = Sample.find(file_selector_params[:attachable])
  end

  def index
    @index = file_selector_params[:index]
  end

  def name
    @name = file_selector_params[:name]
  end

  def selected
    return if file_selector_params[:selected_id].nil?

    @selected_id = file_selector_params[:selected_id]
  end

  def attachments
    attachment = Attachment.find(params[:attachment_id])
    @attachment_params = {filename: attachment.filename.to_s, global_id: attachment.to_global_id, id: attachment.id}

    return unless attachment.associated_attachment && (file_selector_params[:name] == 'fastq_1' || file_selector_params[:name == 'fastq_2'])
    associated_attachment = attachment.associated_attachment
    @associated_attachment_params = {filename: associated_attachment.filename.to_s, global_id: associated_attachment.to_global_id, id: associated_attachment.id}
  end
end
