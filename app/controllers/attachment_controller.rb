# frozen_string_literal: true

class AttachmentController < ApplicationController
  def show
    render plain: "Showing attachment #{params[:id]}"
  end

  def destroy
    render plain: "Deleting attachment #{params[:id]}"
  end
end
