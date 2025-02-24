# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata File Import Controller
      class FileImportsController < Projects::ApplicationController
        include MetadataFileImportActions

        respond_to :turbo_stream

        private

        def namespace
          @namespace = @project.namespace
        end
      end
    end
  end
end
