# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata File Import Controller
      class FileImportController < Projects::Samples::ApplicationController
        # respond_to :turbo_stream

        def create
          # authorize! @project, to: :update_sample?

          # response = ::Samples::Metadata::FileImportController.new(@project, @sample, current_user,
          #                                                          file_import_params).execute

          # pp response

          render status: :ok
        end

        # private

        # def file_import_params
        #   params.require(:file_import).permit(:file, :sample_id_column, :ignore_empty_values)
        # end
      end
    end
  end
end
