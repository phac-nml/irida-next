# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata File Import Controller
      class FileImportsController < Projects::ApplicationController
        respond_to :turbo_stream

        def create # rubocop:disable Metrics/AbcSize
          @namespace = @project.namespace
          authorize! @namespace, to: :update_sample_metadata?
          @imported_metadata = ::Samples::Metadata::FileImportService.new(@namespace, current_user,
                                                                          file_import_params).execute
          if @namespace.errors.empty?
            render status: :ok, locals: { type: :success, message: t('.success') }
          elsif @namespace.errors.include?(:sample)
            errors = @namespace.errors.messages_for(:sample)
            render status: :partial_content, locals: { type: :alert, message: t('.error'), errors: }
          else
            error = @namespace.errors.full_messages_for(:base).first
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
