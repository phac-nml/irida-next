# frozen_string_literal: true

module Groups
  module Samples
    module Metadata
      # Controller actions for Group Samples Metadata File Import Controller
      class FileImportsController < Groups::ApplicationController
        before_action :group, only: %i[create]
        respond_to :turbo_stream

        def create
          authorize! @group, to: :update_sample_metadata?
          @imported_metadata = ::Samples::Metadata::FileImportService.new(@group, current_user,
                                                                          file_import_params).execute
          if @group.errors.empty?
            render status: :ok, locals: { type: :success, message: t('.success') }
          elsif @group.errors.include?(:sample)
            errors = @group.errors.messages_for(:sample)
            render status: :partial_content, locals: { type: :alert, message: t('.error'), errors: }
          else
            error = @group.errors.full_messages_for(:base).first
            render status: :unprocessable_entity, locals: { type: :danger, message: error }
          end
        end

        private

        def file_import_params
          params.require(:file_import).permit(:file, :sample_id_column, :ignore_empty_values)
        end

        def group
          @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
        end
      end
    end
  end
end
