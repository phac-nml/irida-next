# frozen_string_literal: true

module WorkflowExecutions
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @samples = Sample.where(id: params[:sample_ids])
      @header = params[:header]
      @name_format = params[:name_format]
      @field = params[:field]
      render status: :ok
    end
  end
end
