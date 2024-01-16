# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata File Import Controller
      class FileImportController < ApplicationController
        # respond_to :turbo_stream

        def create
          render status: :ok
        end
      end
    end
  end
end
