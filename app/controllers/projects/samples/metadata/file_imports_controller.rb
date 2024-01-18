# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata File Import Controller
      class FileImportsController < Projects::ApplicationController
        respond_to :turbo_stream

        def create
          authorize! @project, to: :update_sample?
          @imported_metadata = ::Samples::Metadata::FileImportService.new(@project, current_user,
                                                                          file_import_params).execute
          if @project.errors.empty?
            render status: :ok, locals: { type: :success, message: t('.success') }
          elsif @project.errors.include?(:sample)
            errors = @project.errors.messages_for(:sample)
            render status: :partial_content, locals: { type: :alert, message: t('.error'), errors: }
          else
            error = @project.errors.full_messages_for(:base).first
            render status: :unprocessable_entity, locals: { type: :danger, message: error }
          end
        end

        private

        def file_import_params
          params.require(:file_import).permit(:file, :sample_id_column, :ignore_empty_values)
        end
      end
    end
  end
end
