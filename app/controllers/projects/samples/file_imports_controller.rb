# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples File Import Controller
    class FileImportsController < Projects::ApplicationController
      include SampleFileImportActions

      respond_to :turbo_stream

      private

      def namespace
        @namespace = @project.namespace
      end
    end
  end
end
