# frozen_string_literal: true

# Controller actions for Projects
class FileSelectorController < ApplicationController
  before_action :attachable, only: %i[new create]
  def new
    render turbo_stream: turbo_stream.update('file_selector_dialog',
                                               partial: 'file_selector/file_selector_dialog',
                                               locals: {attachable: @attachable, open: true}), status: :ok
  end

  def create
    respond_to do |format|
      format.turbo_stream do
        render status:, locals: { test: params[:test] }
      end
    end
  end

  private

  def attachable
    @attachable = Sample.find(params[:attachable])
  end
end
