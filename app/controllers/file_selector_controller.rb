# frozen_string_literal: true

# Controller actions for Projects
class FileSelectorController < ApplicationController
  before_action :attachable, :index, only: %i[new create]
  before_action :selected, only: %i[new]
  before_action :attachment, only: %i[create]

  def new
    render turbo_stream: turbo_stream.update('file_selector_dialog',
                                               partial: 'file_selector/file_selector_dialog',
                                               locals: {attachable: @attachable, open: true}), status: :ok
  end

  def create
    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  private

  def attachable
    @attachable = Sample.find(params[:attachable])
  end

  def index
    @index = params[:index]
  end

  def selected
    return if params[:selected_id].nil?

    @selected_id = params[:selected_id]
  end

  def attachment
    attachment = Attachment.find(params[:attachment_id])
    @attachment_params = {filename: attachment.filename.to_s, global_id: attachment.to_global_id, id: attachment.id}
  end
end
