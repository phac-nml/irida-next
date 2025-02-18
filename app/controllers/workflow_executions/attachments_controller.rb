# frozen_string_literal: true

module WorkflowExecutions
  # Controller for managing attachments related to workflow executions
  class AttachmentsController < ApplicationController
    def index
      @attachment = Attachment.find_by(id: params[:attachment])
      @foo = params[:attachment]
    end
  end
end
