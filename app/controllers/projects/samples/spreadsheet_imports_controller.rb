# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Spreadsheet Import Controller
    class SpreadsheetImportsController < Projects::ApplicationController
      include SampleFileImportActions

      before_action :ensure_enabled

      respond_to :turbo_stream

      private

      def namespace
        @namespace = @project.namespace
      end

      def ensure_enabled
        not_found unless Flipper.enabled?(:batch_sample_file_import)
      end
    end
  end
end
